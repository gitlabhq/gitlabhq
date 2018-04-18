module Gitlab
  module Database
    module LoadBalancing
      # A list of database hosts to use for connections.
      class HostList
        attr_reader :hosts

        # hosts - The list of secondary hosts to add.
        def initialize(hosts = [])
          @hosts = hosts.shuffle
          @index = 0
          @mutex = Mutex.new
        end

        def length
          @hosts.length
        end

        # Returns the next available host.
        #
        # Returns a Gitlab::Database::LoadBalancing::Host instance, or nil if no
        # hosts were available.
        def next
          @mutex.synchronize do
            started_at = @index

            loop do
              host = @hosts[@index]
              @index = (@index + 1) % @hosts.length

              break host if host.online?

              # Return nil once we have cycled through all hosts and none were
              # available.
              break if @index == started_at
            end
          end
        end
      end
    end
  end
end
