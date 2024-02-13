# frozen_string_literal: true

require 'yaml'
require 'sidekiq/capsule'

module Gitlab
  module SidekiqConfig
    FOSS_QUEUE_CONFIG_PATH = 'app/workers/all_queues.yml'
    EE_QUEUE_CONFIG_PATH = 'ee/app/workers/all_queues.yml'
    JH_QUEUE_CONFIG_PATH = 'jh/app/workers/all_queues.yml'
    SIDEKIQ_QUEUES_PATH = 'config/sidekiq_queues.yml'
    JH_SIDEKIQ_QUEUES_PATH = 'jh/config/sidekiq_queues.yml'

    QUEUE_CONFIG_PATHS = [
      FOSS_QUEUE_CONFIG_PATH,
      (EE_QUEUE_CONFIG_PATH if Gitlab.ee?),
      (JH_QUEUE_CONFIG_PATH if Gitlab.jh?)
    ].compact.freeze

    # This maps workers not in our application code to queues. We need
    # these queues in our YAML files to ensure we don't accidentally
    # miss jobs from these queues.
    #
    # The default queue should be unused, which is why it maps to an
    # invalid class name. We keep it in the YAML file for safety, just
    # in case anything does get scheduled to run there.
    DEFAULT_WORKERS = {
      '_' => DummyWorker.new(
        queue: 'default',
        weight: 1,
        tags: []
      ),
      'ActionMailer::MailDeliveryJob' => DummyWorker.new(
        name: 'ActionMailer::MailDeliveryJob',
        queue: 'mailers',
        urgency: 'low',
        weight: 2,
        tags: []
      )
    }.transform_values { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: false, jh: false) }.freeze

    class << self
      include Gitlab::SidekiqConfig::CliMethods
      include Gitlab::Utils::StrongMemoize

      def config_queues
        @config_queues ||= begin
          config = YAML.load_file(Rails.root.join(SIDEKIQ_QUEUES_PATH))
          config[:queues].map(&:first)
        end
      end

      def cron_jobs
        Gitlab.config.load_dynamic_cron_schedules!

        jobs = Gitlab.config.cron_jobs.to_hash

        jobs.delete('poll_interval') # Would be interpreted as a job otherwise

        # Settingslogic (former gem used for yaml configuration) didn't allow 'class' key
        # Therefore, we configure cron jobs with `job_class` as a workaround.
        required_keys = %w[job_class cron]
        jobs.each do |k, v|
          if jobs[k] && required_keys.all? { |s| jobs[k].key?(s) }
            jobs[k]['class'] = jobs[k].delete('job_class')
          else
            jobs.delete(k)
            Gitlab::AppLogger.error("Invalid cron_jobs config key: '#{k}'. Check your gitlab config file.")
          end
        end

        jobs
      end
      strong_memoize_attr :cron_jobs

      def cron_workers
        @cron_workers ||= cron_jobs.map { |job_name, options| options['class'].constantize }
      end

      def workers
        @workers ||= begin
          result = []
          result.concat(DEFAULT_WORKERS.values)
          result.concat(find_workers(Rails.root.join('app', 'workers'), ee: false, jh: false))

          if Gitlab.ee?
            result.concat(find_workers(Rails.root.join('ee', 'app', 'workers'), ee: true, jh: false))
          end

          if Gitlab.jh?
            result.concat(find_workers(Rails.root.join('jh', 'app', 'workers'), ee: false, jh: true))
          end

          result
        end
      end

      def workers_for_all_queues_yml
        workers.each_with_object([[], [], []]) do |worker, array|
          if worker.jh?
            array[2].push(worker)
          elsif worker.ee?
            array[1].push(worker)
          else
            array[0].push(worker)
          end
        end.map(&:sort)
      end

      # YAML.load_file is OK here as we control the file contents
      def all_queues_yml_outdated?
        foss_workers, ee_workers, jh_workers = workers_for_all_queues_yml

        return true if foss_workers != YAML.load_file(FOSS_QUEUE_CONFIG_PATH)

        return true if Gitlab.ee? && ee_workers != YAML.load_file(EE_QUEUE_CONFIG_PATH)

        Gitlab.jh? && File.exist?(JH_QUEUE_CONFIG_PATH) && jh_workers != YAML.load_file(JH_QUEUE_CONFIG_PATH)
      end

      def queues_for_sidekiq_queues_yml
        namespaces_with_equal_weights =
          workers
            .reject { |worker| worker.jh? }
            .group_by(&:queue_namespace)
            .map(&:last)
            .select { |workers| workers.map(&:get_weight).uniq.count == 1 }
            .map(&:first)

        namespaces = namespaces_with_equal_weights.map(&:queue_namespace).to_set
        remaining_queues = workers.reject { |worker| worker.jh? }.reject { |worker| namespaces.include?(worker.queue_namespace) }

        (namespaces_with_equal_weights.map(&:namespace_and_weight) +
         remaining_queues.map(&:queue_and_weight)).sort
      end

      # Override in JH repo
      def jh_queues_for_sidekiq_queues_yml
        []
      end

      # YAML.load_file is OK here as we control the file contents
      def sidekiq_queues_yml_outdated?
        config_queues = YAML.load_file(SIDEKIQ_QUEUES_PATH)[:queues]

        queues_for_sidekiq_queues_yml != config_queues
      end

      # Returns a hash of worker class name => mapped queue name
      def worker_queue_mappings
        workers
          .reject { |worker| worker.klass.is_a?(Gitlab::SidekiqConfig::DummyWorker) }
          .to_h { |worker| [worker.klass.to_s, ::Gitlab::SidekiqConfig::WorkerRouter.global.route(worker.klass)] }
      end

      # Like worker_queue_mappings, but only for the queues running in
      # the current Sidekiq process
      def current_worker_queue_mappings
        worker_queue_mappings
          .select { |worker, queue| Sidekiq.default_configuration.queues.include?(queue) }
          .to_h
      end

      # Get the list of queues from all available workers following queue
      # routing rules. Sidekiq::Queue.all fetches the list of queues from Redis.
      # It may contain some redundant, obsolete queues from previous iterations
      # of GitLab.
      def routing_queues
        @routing_queues ||= workers.map do |worker|
          if worker.klass.is_a?(Gitlab::SidekiqConfig::DummyWorker)
            worker.queue
          else
            ::Gitlab::SidekiqConfig::WorkerRouter.global.route(worker.klass)
          end
        end.uniq.sort
      end

      private

      def find_workers(root, ee:, jh:)
        concerns = root.join('concerns').to_s

        Dir[root.join('**', '*.rb')]
          .reject { |path| path.start_with?(concerns) }
          .map { |path| worker_from_path(path, root) }
          .select { |worker| worker < Sidekiq::Worker }
          .map { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: ee, jh: jh) }
      end

      def worker_from_path(path, root)
        ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

        ns.camelize.constantize
      end
    end
  end
end

Gitlab::SidekiqConfig.prepend_mod
