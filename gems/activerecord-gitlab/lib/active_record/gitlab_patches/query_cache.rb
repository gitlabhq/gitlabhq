# frozen_string_literal: true

# Fixes https://github.com/rails/rails/issues/55689 in Rails 7.2+
# See https://github.com/rails/rails/pull/55703
return if ActiveRecord.version < Gem::Version.new('7.2')

# Changes to the methods are marked with comments starting with PATCH
raise 'Update this patch when upgrading Rails.' if ActiveRecord.version >= Gem::Version.new("7.3")

# rubocop:disable Layout/LineLength -- better to match formatting from upstream code
# rubocop:disable Gitlab/ModuleWithInstanceVariables -- needed for patch
module ActiveRecord
  module ConnectionAdapters
    class NullPool
      def query_cache; end
    end

    class ConnectionPool
      def pin_connection!(lock_thread)
        @pinned_connection ||= (connection_lease&.connection || checkout)
        @pinned_connections_depth += 1

        # Any leased connection must be in @connections otherwise
        # some methods like #connected? won't behave correctly
        unless @connections.include?(@pinned_connection) # rubocop:disable Style/IfUnlessModifier -- upstream code
          @connections << @pinned_connection
        end

        @pinned_connection.lock_thread = ActiveSupport::IsolatedExecutionState.context if lock_thread
        @pinned_connection.pinned = true # PATCH: This line was added
        @pinned_connection.verify! # eagerly validate the connection
        @pinned_connection.begin_transaction joinable: false, _lazy: false
      end

      def unpin_connection!
        raise "There isn't a pinned connection #{object_id}" unless @pinned_connection

        clean = true
        @pinned_connection.lock.synchronize do
          @pinned_connections_depth -= 1
          connection = @pinned_connection
          @pinned_connection = nil if @pinned_connections_depth.zero?

          if connection.transaction_open?
            connection.rollback_transaction
          else
            # Something committed or rolled back the transaction
            clean = false
            connection.reset!
          end

          if @pinned_connection.nil?
            connection.pinned = false # PATCH: This line was added
            connection.steal!
            connection.lock_thread = nil
            checkin(connection)
          end
        end

        clean
      end
    end

    class AbstractAdapter
      attr_accessor :pinned
    end

    module QueryCache
      def query_cache
        if @pinned && @owner != ActiveSupport::IsolatedExecutionState.context
          # With transactional tests, if the connection is pinned, any thread
          # other than the one that pinned the connection need to go through the
          # query cache pool, so each thread get a different cache.
          pool.query_cache
        else
          @query_cache
        end
      end

      def query_cache_enabled
        query_cache&.enabled?
      end

      def select_all(arel, name = nil, binds = [], preparable: nil, async: false, allow_retry: false)
        arel = arel_from_relation(arel)

        # If arel is locked this is a SELECT ... FOR UPDATE or somesuch.
        # Such queries should not be cached.
        if query_cache_enabled && !(arel.respond_to?(:locked) && arel.locked) # PATCH: @query_cache&.enabled? was changed to query_cache_enabled
          sql, binds, preparable, allow_retry = to_sql_and_binds(arel, binds, preparable, allow_retry)

          if async
            result = lookup_sql_cache(sql, name, binds) || super(sql, name, binds, preparable: preparable, async: async, allow_retry: allow_retry)
            FutureResult.wrap(result)
          else
            cache_sql(sql, name, binds) { super(sql, name, binds, preparable: preparable, async: async, allow_retry: allow_retry) }
          end
        else
          super
        end
      end

      private

      def lookup_sql_cache(sql, name, binds)
        key = binds.empty? ? sql : [sql, binds]

        result = nil
        @lock.synchronize do
          result = query_cache[key] # PATCH: @query_cache was changed to query_cache
        end

        if result
          ActiveSupport::Notifications.instrument(
            "sql.active_record",
            cache_notification_info(sql, name, binds)
          )
        end

        result
      end

      def cache_sql(sql, name, binds)
        key = binds.empty? ? sql : [sql, binds]
        result = nil
        hit = true

        @lock.synchronize do
          result = query_cache.compute_if_absent(key) do # PATCH: @query_cache was changed to query_cache
            hit = false
            yield
          end
        end

        if hit
          ActiveSupport::Notifications.instrument(
            "sql.active_record",
            cache_notification_info(sql, name, binds)
          )
        end

        result.dup
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Gitlab/ModuleWithInstanceVariables
