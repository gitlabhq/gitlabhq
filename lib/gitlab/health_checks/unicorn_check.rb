# frozen_string_literal: true

module Gitlab
  module HealthChecks
    # This check can only be run on Unicorn `master` process
    class UnicornCheck
      extend SimpleAbstractCheck

      class << self
        include Gitlab::Utils::StrongMemoize

        private

        def metric_prefix
          'unicorn_check'
        end

        def successful?(result)
          result > 0
        end

        def check
          return unless http_servers

          http_servers.sum(&:worker_processes) # rubocop: disable CodeReuse/ActiveRecord
        end

        # Traversal of ObjectSpace is expensive, on fully loaded application
        # it takes around 80ms. The instances of HttpServers are not a subject
        # to change so we can cache the list of servers.
        def http_servers
          strong_memoize(:http_servers) do
            next unless Gitlab::Runtime.unicorn?

            ObjectSpace.each_object(::Unicorn::HttpServer).to_a
          end
        end
      end
    end
  end
end
