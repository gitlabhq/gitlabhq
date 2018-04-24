module Geo
  module RepositoryVerification
    module Secondary
      class SingleWorker
        include ApplicationWorker
        include GeoQueue
        include ExclusiveLeaseGuard
        include Gitlab::Geo::ProjectLogHelpers

        LEASE_TIMEOUT = 1.hour.to_i

        attr_reader :registry
        private     :registry

        delegate :project, to: :registry

        def perform(registry_id)
          return unless Gitlab::Geo.secondary?

          @registry = Geo::ProjectRegistry.find_by_id(registry_id)
          return if registry.nil? || project.nil? || project.pending_delete?

          try_obtain_lease do
            verify_checksum(:repository)
            verify_checksum(:wiki)
          end
        end

        private

        def verify_checksum(type)
          Geo::RepositoryVerifySecondaryService.new(registry, type).execute
        rescue => e
          log_error('Error verifying the repository checksum', e, type: type)
          raise e
        end

        def lease_key
          "geo:repository_verification:secondary:single_worker:#{project.id}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end
      end
    end
  end
end
