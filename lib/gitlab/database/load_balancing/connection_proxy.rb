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
          transaction
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

        # Delegates all unknown messages to a read-write connection.
        def method_missing(name, *args, &block)
          write_using_load_balancer(name, args, &block)
        end

        # Performs a read using the load balancer.
        #
        # name - The name of the method to call on a connection object.
        def read_using_load_balancer(name, args, &block)
          method = Session.current.use_primary? ? :read_write : :read

          @load_balancer.send(method) do |connection|
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

          result
        end
      end
    end
  end
end
