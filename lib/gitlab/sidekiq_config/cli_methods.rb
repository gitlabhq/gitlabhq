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

      QUEUE_CONFIG_PATHS = begin
        result = %w[app/workers/all_queues.yml]
        result << 'ee/app/workers/all_queues.yml' if Gitlab.ee?
        result
      end.freeze

      def worker_queues(rails_path = Rails.root.to_s)
        @worker_queues ||= {}

        @worker_queues[rails_path] ||= QUEUE_CONFIG_PATHS.flat_map do |path|
          full_path = File.join(rails_path, path)
          queues = File.exist?(full_path) ? YAML.load_file(full_path) : []

          # https://gitlab.com/gitlab-org/gitlab/issues/199230
          queues.map { |queue| queue.is_a?(Hash) ? queue[:name] : queue }
        end
      end

      def expand_queues(queues, all_queues = self.worker_queues)
        return [] if queues.empty?

        queues_set = all_queues.to_set

        queues.flat_map do |queue|
          [queue, *queues_set.grep(/\A#{queue}:/)]
        end
      end

      def clear_memoization!
        if instance_variable_defined?('@worker_queues')
          remove_instance_variable('@worker_queues')
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
