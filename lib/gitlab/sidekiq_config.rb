# frozen_string_literal: true

require 'yaml'

module Gitlab
  module SidekiqConfig
    class << self
      include Gitlab::SidekiqConfig::CliMethods

      def redis_queues
        # Not memoized, because this can change during the life of the application
        Sidekiq::Queue.all.map(&:name)
      end

      def config_queues
        @config_queues ||= begin
          config = YAML.load_file(Rails.root.join('config/sidekiq_queues.yml'))
          config[:queues].map(&:first)
        end
      end

      def cron_workers
        @cron_workers ||= Settings.cron_jobs.map { |job_name, options| options['job_class'].constantize }
      end

      def workers
        @workers ||= begin
          result = find_workers(Rails.root.join('app', 'workers'))
          result.concat(find_workers(Rails.root.join('ee', 'app', 'workers'))) if Gitlab.ee?
          result
        end
      end

      private

      def find_workers(root)
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
end
