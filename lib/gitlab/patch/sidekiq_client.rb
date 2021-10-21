# frozen_string_literal: true

module Gitlab
  module Patch
    module SidekiqClient
      private

      # This is a copy of https://github.com/mperham/sidekiq/blob/v6.2.2/lib/sidekiq/client.rb#L187-L194
      # but using `conn.pipelined` instead of `conn.multi`. The multi call isn't needed here because in
      # the case of scheduled jobs, only one Redis call is made. For other jobs, we don't really need
      # the commands to be atomic.
      def raw_push(payloads)
        @redis_pool.with do |conn| # rubocop:disable Gitlab/ModuleWithInstanceVariables
          conn.pipelined do
            atomic_push(conn, payloads)
          end
        end
        true
      end
    end
  end
end
