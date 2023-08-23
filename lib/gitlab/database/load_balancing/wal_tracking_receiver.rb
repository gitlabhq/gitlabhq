# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      module WalTrackingReceiver
        # NOTE: If there's no entry for a load balancer or no WAL locations were passed
        # we assume the sender does not care about LB and we assume nodes are in-sync.
        def databases_in_sync?(wal_locations)
          return true unless wal_locations.present?

          ::Gitlab::Database::LoadBalancing.each_load_balancer.all? do |lb|
            if (location = wal_locations.with_indifferent_access[lb.name])
              lb.select_up_to_date_host(location) != LoadBalancer::NONE_CAUGHT_UP
            else
              true
            end
          end
        end
      end
    end
  end
end
