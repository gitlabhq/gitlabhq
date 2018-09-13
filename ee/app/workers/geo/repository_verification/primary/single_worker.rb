module Geo
  module RepositoryVerification
    module Primary
      class SingleWorker
        include ApplicationWorker
        include GeoQueue
        include ExclusiveLeaseGuard

        LEASE_TIMEOUT = 1.hour.to_i

        attr_reader :project

        # rubocop: disable CodeReuse/ActiveRecord
        def perform(project_id)
          return unless Gitlab::Geo.primary?

          @project = Project.find_by(id: project_id)
          return if project.nil? || project.pending_delete?

          try_obtain_lease do
            Geo::RepositoryVerificationPrimaryService.new(project).execute
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        def lease_key
          "geo:single_repository_verification_worker:#{project.id}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end
      end
    end
  end
end
