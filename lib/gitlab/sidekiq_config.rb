require 'yaml'

module Gitlab
  module SidekiqConfig
    def self.redis_queues
      @redis_queues ||= Sidekiq::Queue.all.map(&:name)
    end

    # This method is called by `bin/sidekiq-cluster` in EE, which runs outside
    # of bundler/Rails context, so we cannot use any gem or Rails methods.
    def self.config_queues(rails_path = Rails.root.to_s)
      @config_queues ||= begin
        config = YAML.load_file(File.join(rails_path, 'config', 'sidekiq_queues.yml'))
        config[:queues].map(&:first)
      end
    end

    def self.cron_workers
      @cron_workers ||= Settings.cron_jobs.map { |job_name, options| options['job_class'].constantize }
    end

    def self.workers
      @workers ||=
        find_workers(Rails.root.join('app', 'workers')) +
        find_workers(Rails.root.join('ee', 'app', 'workers'))
    end

    def self.default_queues
      [ActionMailer::DeliveryJob.queue_name, 'default']
    end

    def self.worker_queues
      @worker_queues ||= (workers.map(&:queue) + default_queues).uniq
    end

    def self.find_workers(root)
      concerns = root.join('concerns').to_s

      workers = Dir[root.join('**', '*.rb')]
        .reject { |path| path.start_with?(concerns) }

      workers.map! do |path|
        ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

        ns.camelize.constantize
      end

      # Skip concerns
      workers.select { |w| w < Sidekiq::Worker }
    end
  end
end
