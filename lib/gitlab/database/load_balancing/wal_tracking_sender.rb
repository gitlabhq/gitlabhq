# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      module WalTrackingSender
        def wal_locations_by_db_name
          {}.tap do |locations|
            ::Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
              if (location = wal_location_for(lb))
                locations[lb.name] = location
              end
            end
          end
        end

        def wal_location_for(load_balancer)
          # When only using the primary there's no need for any WAL queries.
          return if load_balancer.primary_only?

          if Session.current.use_primary?
            load_balancer.primary_write_location
          else
            load_balancer.host&.database_replica_location || load_balancer.primary_write_location
          end
        end
      end
    end
  end
end
