# frozen_string_literal: true

module Gitlab
  module Patch
    module ConnectionPoolExtendedStat
      def extended_stat
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This patch must access @connections from ConnectionPool
        synchronize do
          {
            size: size,
            connections: @connections.size,
            busy_by_thread_name: thread_connection_counts(@connections.select { |c| c.in_use? && c.owner.alive? }),
            dead_by_thread_name: thread_connection_counts(@connections.select { |c| c.in_use? && !c.owner.alive? }),
            idle: @connections.count { |c| !c.in_use? },
            waiting: num_waiting_in_queue,
            checkout_timeout: checkout_timeout
          }
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end

      private

      def thread_connection_counts(connections)
        connections.group_by { |c| c.owner.name || "unnamed" }.transform_values(&:count)
      end
    end
  end
end
