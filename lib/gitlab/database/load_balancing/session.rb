# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Tracking of load balancing state per user session.
      #
      # A session starts at the beginning of a request and ends once the request
      # has been completed. Sessions can be used to keep track of what hosts
      # should be used for queries.
      class Session
        def initialize
          @use_primary = false
          @performed_write = false
          @ignore_writes = false
          @fallback_to_replicas_for_ambiguous_queries = false
          @use_replicas_for_read_queries = false
        end

        def use_primary?
          @use_primary
        end

        alias_method :using_primary?, :use_primary?

        def use_primary!
          @use_primary = true
        end

        def use_primary
          used_primary = @use_primary
          @use_primary = true
          yield
        ensure
          @use_primary = used_primary || @performed_write
        end

        def ignore_writes
          @ignore_writes = true

          yield
        ensure
          @ignore_writes = false
        end
        alias_method :without_sticky_writes, :ignore_writes

        # Indicates that the read SQL statements from anywhere inside this
        # blocks should use a replica, regardless of the current primary
        # stickiness or whether a write query is already performed in the
        # current session. This interface is reserved mostly for performance
        # purpose. This is a good tool to push expensive queries, which can
        # tolerate the replica lags, to the replicas.
        #
        # Write and ambiguous queries inside this block are still handled by
        # the primary.
        def use_replicas_for_read_queries
          previous_flag = @use_replicas_for_read_queries
          @use_replicas_for_read_queries = true
          yield
        ensure
          @use_replicas_for_read_queries = previous_flag
        end

        def use_replicas_for_read_queries?
          @use_replicas_for_read_queries == true
        end

        # Indicate that the ambiguous SQL statements from anywhere inside this
        # block should use a replica. The ambiguous statements include:
        # - Transactions.
        # - Custom queries (via exec_query, execute, etc.)
        # - In-flight connection configuration change (SET LOCAL statement_timeout = 5000)
        #
        # This is a weak enforcement. This helper incorporates well with
        # primary stickiness:
        # - If the queries are about to write
        # - The current session already performed writes
        # - It prefers to use primary, aka, use_primary or use_primary! were called
        def fallback_to_replicas_for_ambiguous_queries
          previous_flag = @fallback_to_replicas_for_ambiguous_queries
          @fallback_to_replicas_for_ambiguous_queries = true
          yield
        ensure
          @fallback_to_replicas_for_ambiguous_queries = previous_flag
        end

        def fallback_to_replicas_for_ambiguous_queries?
          @fallback_to_replicas_for_ambiguous_queries == true && !use_primary? && !performed_write?
        end

        def write!
          @performed_write = true

          return if @ignore_writes

          use_primary!
        end

        def performed_write?
          @performed_write
        end
      end
    end
  end
end
