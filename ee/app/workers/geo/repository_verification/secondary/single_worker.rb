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

        # rubocop: disable CodeReuse/ActiveRecord
        def perform(registry_id)
          return unless Gitlab::Geo.secondary?

          @registry = Geo::ProjectRegistry.find_by(id: registry_id)
          return if registry.nil? || project.nil? || project.pending_delete?

          try_obtain_lease do
            verify_checksum(:repository)
            verify_checksum(:wiki)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        def verify_checksum(type)
          Geo::RepositoryVerificationSecondaryService.new(registry, type).execute
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
