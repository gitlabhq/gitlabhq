# frozen_string_literal: true

module Gitlab
  module Database
    # Transactions and SET LOCAL stick the load-balancing session to the primary.
    # A read-only block that needs them can run on a replica instead.
    module ReplicaFallback
      def with_replica_fallback(database_model, &)
        ::Gitlab::Database::LoadBalancing::SessionMap
          .current(database_model.load_balancer)
          .fallback_to_replicas_for_ambiguous_queries(&)
      end
    end
  end
end
