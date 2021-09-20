# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # A list of database hosts to use for connections.
      class HostList
        # hosts - The list of secondary hosts to add.
        def initialize(hosts = [])
          @hosts = hosts.shuffle
          @index = 0
          @mutex = Mutex.new
          @hosts_gauge = Gitlab::Metrics.gauge(:db_load_balancing_hosts, 'Current number of load balancing hosts')

          set_metrics!
        end

        def hosts
          @mutex.synchronize { @hosts.dup }
        end

        def shuffle
          @mutex.synchronize do
            unsafe_shuffle
          end
        end

        def length
          @mutex.synchronize { @hosts.length }
        end

        def host_names_and_ports
          @mutex.synchronize { @hosts.map { |host| [host.host, host.port] } }
        end

        def hosts=(hosts)
          @mutex.synchronize do
            @hosts = hosts
            unsafe_shuffle
          end

          set_metrics!
        end

        # Sets metrics before returning next host
        def next
          next_host.tap do |_|
            set_metrics!
          end
        end

        private

        def unsafe_shuffle
          @hosts = @hosts.shuffle
          @index = 0
        end

        # Returns the next available host.
        #
        # Returns a Gitlab::Database::LoadBalancing::Host instance, or nil if no
        # hosts were available.
        def next_host
          @mutex.synchronize do
            break if @hosts.empty?

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

        def set_metrics!
          @hosts_gauge.set({}, @hosts.length)
        end
      end
    end
  end
end
