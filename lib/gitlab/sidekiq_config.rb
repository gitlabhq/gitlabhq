require 'yaml'
require 'set'

module Gitlab
  module SidekiqConfig
    # This method is called by `bin/sidekiq-cluster` in EE, which runs outside
    # of bundler/Rails context, so we cannot use any gem or Rails methods.
    def self.worker_queues(rails_path = Rails.root.to_s)
      @worker_queues ||= {}
      @worker_queues[rails_path] ||= YAML.load_file(File.join(rails_path, 'app/workers/all_queues.yml'))
    end

    # This method is called by `bin/sidekiq-cluster` in EE, which runs outside
    # of bundler/Rails context, so we cannot use any gem or Rails methods.
    def self.expand_queues(queues, all_queues = self.worker_queues)
      return [] if queues.empty?

      queues_set = all_queues.to_set

      queues.flat_map do |queue|
        [queue, *queues_set.grep(/\A#{queue}:/)]
      end
    end

    def self.redis_queues
      # Not memoized, because this can change during the life of the application
      Sidekiq::Queue.all.map(&:name)
    end

    def self.config_queues
      @config_queues ||= begin
        config = YAML.load_file(Rails.root.join('config/sidekiq_queues.yml'))
        config[:queues].map(&:first)
      end
    end

    def self.cron_workers
      @cron_workers ||= Settings.cron_jobs.map { |job_name, options| options['job_class'].constantize }
    end

    def self.workers
      @workers ||= find_workers(Rails.root.join('app', 'workers'))
    end

    def self.find_workers(root)
      concerns = root.join('concerns').to_s

      workers = Dir[root.join('**', '*.rb')]
        .reject { |path| path.start_with?(concerns) }

      workers.map! do |path|
        ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

        ns.camelize.constantize
      end

      # Skip things that aren't workers
      workers.select { |w| w < Sidekiq::Worker }
    end
  end
end
