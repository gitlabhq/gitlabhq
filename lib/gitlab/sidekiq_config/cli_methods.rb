# frozen_string_literal: true

require 'yaml'
require 'set'

# These methods are called by `sidekiq-cluster`, which runs outside of
# the bundler/Rails context, so we cannot use any gem or Rails methods.
module Gitlab
  module SidekiqConfig
    module CliMethods
      # The methods in this module are used as module methods
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      extend self

      # The file names are misleading. Those files contain the metadata of the
      # workers. They should be renamed to all_workers instead.
      # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1018
      QUEUE_CONFIG_PATHS = begin
        result = %w[app/workers/all_queues.yml]
        result << 'ee/app/workers/all_queues.yml' if Gitlab.ee?
        result
      end.freeze

      def worker_metadatas(rails_path = Rails.root.to_s)
        @worker_metadatas ||= {}

        @worker_metadatas[rails_path] ||= QUEUE_CONFIG_PATHS.flat_map do |path|
          full_path = File.join(rails_path, path)

          File.exist?(full_path) ? YAML.load_file(full_path) : []
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def worker_queues(rails_path = Rails.root.to_s)
        worker_names(worker_metadatas(rails_path))
      end

      def expand_queues(queues, all_queues = self.worker_queues)
        return [] if queues.empty?

        queues_set = all_queues.to_set

        queues.flat_map do |queue|
          [queue, *queues_set.grep(/\A#{queue}:/)]
        end
      end

      def query_queues(query_string, worker_metadatas)
        matcher = SidekiqConfig::WorkerMatcher.new(query_string)
        selected_metadatas = worker_metadatas.select do |worker_metadata|
          matcher.match?(worker_metadata)
        end

        worker_names(selected_metadatas)
      end

      def clear_memoization!
        if instance_variable_defined?('@worker_metadatas')
          remove_instance_variable('@worker_metadatas')
        end
      end

      private

      def worker_names(workers)
        workers.map { |queue| queue[:name] }
      end
    end
  end
end
