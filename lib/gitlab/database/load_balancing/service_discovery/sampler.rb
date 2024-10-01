# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class ServiceDiscovery
        class Sampler
          def initialize(max_replica_pools:, seed: Random.new_seed)
            # seed must be set once and consistent
            # for every invocation of #sample on
            # the same instance of Sampler
            @seed = seed
            @max_replica_pools = max_replica_pools
          end

          def sample(addresses)
            return addresses if @max_replica_pools.nil? || addresses.count <= @max_replica_pools

            ::Gitlab::Database::LoadBalancing::Logger.debug(
              event: :host_list_limit_exceeded,
              message: "Host list length exceeds max_replica_pools so random hosts will be chosen.",
              max_replica_pools: @max_replica_pools,
              total_host_list_length: addresses.count
            )

            # First sort them in case the ordering from DNS server changes
            # then randomly order all addresses using consistent seed so
            # this process always gives the same set for this instance of
            # Sampler
            addresses = addresses.sort
            addresses = addresses.shuffle(random: Random.new(@seed))

            # Group by hostname so that we can sample evenly across hosts
            addresses_by_host = addresses.group_by(&:hostname)

            selected_addresses = []
            while selected_addresses.count < @max_replica_pools
              # Loop over all hostnames grabbing one address at a time to
              # evenly distribute across all hostnames
              addresses_by_host.each do |host, addresses|
                next if addresses.empty?

                selected_addresses << addresses.pop

                break unless selected_addresses.count < @max_replica_pools
              end
            end

            selected_addresses
          end
        end
      end
    end
  end
end
