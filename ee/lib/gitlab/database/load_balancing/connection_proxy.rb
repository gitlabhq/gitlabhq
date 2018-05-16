# rubocop:disable GitlabSecurity/PublicSend

module Gitlab
  module Database
    module LoadBalancing
      # Redirecting of ActiveRecord connections.
      #
      # The ConnectionProxy class redirects ActiveRecord connection requests to
      # the right load balancer pool, depending on the type of query.
      class ConnectionProxy
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

        # hosts - The hosts to use for load balancing.
        def initialize(hosts = [])
          @load_balancer = LoadBalancer.new(hosts)
        end

        def select(*args)
          read_using_load_balancer(:select, args)
        end

        def select_all(arel, name = nil, binds = [])
          if arel.respond_to?(:locked) && arel.locked
            # SELECT ... FOR UPDATE queries should be sent to the primary.
            write_using_load_balancer(:select_all, [arel, name, binds],
                                      sticky: true)
          else
            read_using_load_balancer(:select_all, [arel, name, binds])
          end
        end

        STICKY_WRITES.each do |name|
          define_method(name) do |*args, &block|
            write_using_load_balancer(name, args, sticky: true, &block)
          end
        end

        def transaction(*args, &block)
          Session.current.enter_transaction

          write_using_load_balancer(:transaction, args, sticky: true, &block)
        ensure
          Session.current.leave_transaction

          # When the transaction finishes we need to store the last WAL pointer
          # since individual writes in a transaction don't perform this
          # operation.
          record_last_write_location
        end

        # Delegates all unknown messages to a read-write connection.
        def method_missing(name, *args, &block)
          write_using_load_balancer(name, args, &block)
        end

        # Performs a read using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        def read_using_load_balancer(name, args, &block)
          @load_balancer.send(load_balancer_method_for_read) do |connection|
            connection.send(name, *args, &block)
          end
        end

        # Performs a write using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        # sticky - If set to true the session will stick to the master after
        #          the write.
        def write_using_load_balancer(name, args, sticky: false, &block)
          result = @load_balancer.read_write do |connection|
            # Sticking has to be enabled before calling the method. Not doing so
            # could lead to methods called in a block still being performed on a
            # secondary instead of on a primary (when necessary).
            Session.current.write! if sticky

            connection.send(name, *args, &block)
          end

          # We only want to record the last write location if we actually
          # performed a write, and not for all queries sent to the primary.
          record_last_write_location if sticky

          result
        end

        # Returns the method to use for performing a read-only query.
        def load_balancer_method_for_read
          session = Session.current

          return :read unless session.use_primary?

          # If we are still inside an explicit transaction we _must_ send the
          # queries to the primary.
          return :read_write if session.in_transaction?

          # If we are not in an explicit transaction we are free to return to
          # using the secondaries once they are all in sync.
          if @load_balancer.all_caught_up?(session.last_write_location)
            session.reset!

            :read
          else
            :read_write
          end
        end

        def record_last_write_location
          session = Session.current

          # When we are in a transaction it's likely we will perform many
          # writes. In this case it's pointless to keep retrieving and storing
          # the WAL location, as we only care about the location once the
          # transaction finishes.
          return if session.in_transaction?

          session.last_write_location = @load_balancer.primary_write_location
        end
      end
    end
  end
end
