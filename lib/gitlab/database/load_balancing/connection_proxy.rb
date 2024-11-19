# frozen_string_literal: true

# rubocop:disable GitlabSecurity/PublicSend

module Gitlab
  module Database
    module LoadBalancing
      # Redirecting of ActiveRecord connections.
      #
      # The ConnectionProxy class redirects ActiveRecord connection requests to
      # the right load balancer pool, depending on the type of query.
      class ConnectionProxy
        WriteInsideReadOnlyTransactionError = Class.new(StandardError)
        READ_ONLY_TRANSACTION_KEY = :load_balacing_read_only_transaction

        attr_reader :load_balancer

        # These methods perform writes after which we need to stick to the
        # primary.
        STICKY_WRITES = %i[
          delete
          delete_all
          insert
          update
          update_all
          exec_insert_all
        ].freeze

        NON_STICKY_READS = %i[
          sanitize_limit
          select
          select_one
          select_rows
          quote_column_name
        ].freeze

        # hosts - The hosts to use for load balancing.
        def initialize(load_balancer)
          @load_balancer = load_balancer
        end

        def select_all(arel, name = nil, binds = [], preparable: nil, async: false)
          if arel.respond_to?(:locked) && arel.locked
            # SELECT ... FOR UPDATE queries should be sent to the primary.
            current_session.write!
            write_using_load_balancer(:select_all, arel, name, binds)
          else
            read_using_load_balancer(:select_all, arel, name, binds)
          end
        end

        NON_STICKY_READS.each do |name|
          define_method(name) do |*args, **kwargs, &block|
            read_using_load_balancer(name, *args, **kwargs, &block)
          end
        end

        STICKY_WRITES.each do |name|
          define_method(name) do |*args, **kwargs, &block|
            current_session.write!
            write_using_load_balancer(name, *args, **kwargs, &block)
          end
        end

        def schema_cache(*args, **kwargs, &block)
          # Ignore primary stickiness for schema_cache queries and always use replicas
          @load_balancer.read do |connection|
            connection.public_send(:schema_cache, *args, **kwargs, &block)
          end
        end

        def transaction(*args, **kwargs, &block)
          if current_session.fallback_to_replicas_for_ambiguous_queries?
            track_read_only_transaction!
            read_using_load_balancer(:transaction, *args, **kwargs, &block)
          else
            current_session.write!
            write_using_load_balancer(:transaction, *args, **kwargs, &block)
          end

        ensure
          untrack_read_only_transaction!
        end

        def respond_to_missing?(name, include_private = false)
          @load_balancer.read_write do |connection|
            connection.respond_to?(name, include_private)
          end
        end

        # Delegates all unknown messages to a read-write connection.
        def method_missing(...)
          if current_session.fallback_to_replicas_for_ambiguous_queries?
            read_using_load_balancer(...)
          else
            write_using_load_balancer(...)
          end
        end

        # Performs a read using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        def read_using_load_balancer(...)
          if current_session.use_primary? &&
              !current_session.use_replicas_for_read_queries?
            @load_balancer.read_write do |connection|
              connection.public_send(...)
            end
          else
            @load_balancer.read do |connection|
              connection.public_send(...)
            end
          end
        end

        # Performs a write using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        # sticky - If set to true the session will stick to the master after
        #          the write.
        def write_using_load_balancer(...)
          if read_only_transaction?
            raise WriteInsideReadOnlyTransactionError, 'A write query is performed inside a read-only transaction'
          end

          @load_balancer.read_write do |connection|
            connection.public_send(...)
          end
        end

        private

        def current_session
          ::Gitlab::Database::LoadBalancing::SessionMap.current(@load_balancer)
        end

        def track_read_only_transaction!
          Thread.current[READ_ONLY_TRANSACTION_KEY] = true
        end

        def untrack_read_only_transaction!
          Thread.current[READ_ONLY_TRANSACTION_KEY] = nil
        end

        def read_only_transaction?
          Thread.current[READ_ONLY_TRANSACTION_KEY] == true
        end
      end
    end
  end
end
