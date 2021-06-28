# frozen_string_literal: true

require 'yaml'

module Gitlab
  module SidekiqConfig
    FOSS_QUEUE_CONFIG_PATH = 'app/workers/all_queues.yml'
    EE_QUEUE_CONFIG_PATH = 'ee/app/workers/all_queues.yml'
    SIDEKIQ_QUEUES_PATH = 'config/sidekiq_queues.yml'

    QUEUE_CONFIG_PATHS = [
      FOSS_QUEUE_CONFIG_PATH,
      (EE_QUEUE_CONFIG_PATH if Gitlab.ee?)
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
        weight: 1, tags: []
      ),
      'ActionMailer::MailDeliveryJob' => DummyWorker.new(
        name: 'ActionMailer::MailDeliveryJob',
        queue: 'mailers',
        feature_category: :issue_tracking,
        urgency: 'low',
        weight: 2,
        tags: []
      )
    }.transform_values { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: false) }.freeze

    class << self
      include Gitlab::SidekiqConfig::CliMethods

      def redis_queues
        # Not memoized, because this can change during the life of the application
        Sidekiq::Queue.all.map(&:name)
      end

      def config_queues
        @config_queues ||= begin
          config = YAML.load_file(Rails.root.join(SIDEKIQ_QUEUES_PATH))
          config[:queues].map(&:first)
        end
      end

      def cron_workers
        @cron_workers ||= Settings.cron_jobs.map { |job_name, options| options['job_class'].constantize }
      end

      def workers
        @workers ||= begin
          result = []
          result.concat(DEFAULT_WORKERS.values)
          result.concat(find_workers(Rails.root.join('app', 'workers'), ee: false))

          if Gitlab.ee?
            result.concat(find_workers(Rails.root.join('ee', 'app', 'workers'), ee: true))
          end

          result
        end
      end

      def workers_for_all_queues_yml
        workers.partition(&:ee?).reverse.map(&:sort)
      end

      # YAML.load_file is OK here as we control the file contents
      def all_queues_yml_outdated?
        foss_workers, ee_workers = workers_for_all_queues_yml

        return true if foss_workers != YAML.load_file(FOSS_QUEUE_CONFIG_PATH)

        Gitlab.ee? && ee_workers != YAML.load_file(EE_QUEUE_CONFIG_PATH)
      end

      def queues_for_sidekiq_queues_yml
        namespaces_with_equal_weights =
          workers
            .group_by(&:queue_namespace)
            .map(&:last)
            .select { |workers| workers.map(&:get_weight).uniq.count == 1 }
            .map(&:first)

        namespaces = namespaces_with_equal_weights.map(&:queue_namespace).to_set
        remaining_queues = workers.reject { |worker| namespaces.include?(worker.queue_namespace) }

        (namespaces_with_equal_weights.map(&:namespace_and_weight) +
         remaining_queues.map(&:queue_and_weight)).sort
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
          .select { |worker, queue| Sidekiq.options[:queues].include?(queue) }
          .to_h
      end

      private

      def find_workers(root, ee:)
        concerns = root.join('concerns').to_s

        Dir[root.join('**', '*.rb')]
          .reject { |path| path.start_with?(concerns) }
          .map { |path| worker_from_path(path, root) }
          .select { |worker| worker < Sidekiq::Worker }
          .map { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: ee) }
      end

      def worker_from_path(path, root)
        ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

        ns.camelize.constantize
      end
    end
  end
end
