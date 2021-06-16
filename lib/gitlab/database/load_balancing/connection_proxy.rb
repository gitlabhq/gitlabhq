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
        STICKY_WRITES = %i(
          delete
          delete_all
          insert
          update
          update_all
        ).freeze

        NON_STICKY_READS = %i(
          sanitize_limit
          select
          select_one
          select_rows
          quote_column_name
        ).freeze

        # hosts - The hosts to use for load balancing.
        def initialize(hosts = [])
          @load_balancer = LoadBalancer.new(hosts)
        end

        def select_all(arel, name = nil, binds = [], preparable: nil)
          if arel.respond_to?(:locked) && arel.locked
            # SELECT ... FOR UPDATE queries should be sent to the primary.
            write_using_load_balancer(:select_all, [arel, name, binds],
                                      sticky: true)
          else
            read_using_load_balancer(:select_all, [arel, name, binds])
          end
        end

        NON_STICKY_READS.each do |name|
          define_method(name) do |*args, &block|
            read_using_load_balancer(name, args, &block)
          end
        end

        STICKY_WRITES.each do |name|
          define_method(name) do |*args, &block|
            write_using_load_balancer(name, args, sticky: true, &block)
          end
        end

        def transaction(*args, &block)
          if current_session.fallback_to_replicas_for_ambiguous_queries?
            track_read_only_transaction!
            read_using_load_balancer(:transaction, args, &block)
          else
            write_using_load_balancer(:transaction, args, sticky: true, &block)
          end

        ensure
          untrack_read_only_transaction!
        end

        # Delegates all unknown messages to a read-write connection.
        def method_missing(name, *args, &block)
          if current_session.fallback_to_replicas_for_ambiguous_queries?
            read_using_load_balancer(name, args, &block)
          else
            write_using_load_balancer(name, args, &block)
          end
        end

        # Performs a read using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        def read_using_load_balancer(name, args, &block)
          if current_session.use_primary? &&
             !current_session.use_replicas_for_read_queries?
            @load_balancer.read_write do |connection|
              connection.send(name, *args, &block)
            end
          else
            @load_balancer.read do |connection|
              connection.send(name, *args, &block)
            end
          end
        end

        # Performs a write using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        # sticky - If set to true the session will stick to the master after
        #          the write.
        def write_using_load_balancer(name, args, sticky: false, &block)
          if read_only_transaction?
            raise WriteInsideReadOnlyTransactionError, 'A write query is performed inside a read-only transaction'
          end

          @load_balancer.read_write do |connection|
            # Sticking has to be enabled before calling the method. Not doing so
            # could lead to methods called in a block still being performed on a
            # secondary instead of on a primary (when necessary).
            current_session.write! if sticky

            connection.send(name, *args, &block)
          end
        end

        private

        def current_session
          ::Gitlab::Database::LoadBalancing::Session.current
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
