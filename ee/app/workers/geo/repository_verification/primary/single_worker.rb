module Geo
  module RepositoryVerification
    module Primary
      class SingleWorker
        include ApplicationWorker
        include GeoQueue
        include ExclusiveLeaseGuard
        include Gitlab::Geo::ProjectLogHelpers

        LEASE_TIMEOUT = 1.hour.to_i

        attr_reader :project

        def perform(project_id)
          return unless Gitlab::Geo.primary?

          @project = Project.find_by(id: project_id)
          return if project.nil? || project.pending_delete?

          try_obtain_lease do
            calculate_repository_checksum if repository_state.repository_checksum_outdated?
            calculate_wiki_checksum if repository_state.wiki_checksum_outdated?
          end
        end

        private

        def calculate_repository_checksum
          calculate_checksum(:repository, project.disk_path)
        end

        def calculate_wiki_checksum
          calculate_checksum(:wiki, project.wiki.disk_path)
        end

        def calculate_checksum(type, repository_relative_path)
          checksum = Gitlab::Git::Checksum.new(project.repository_storage, repository_relative_path)
          update_repository_state!(type, checksum: checksum.calculate)
        rescue => e
          log_error('Error calculating the repository checksum', e, type: type)
          update_repository_state!(type, failure: e.message)
        end

        def update_repository_state!(type, checksum: nil, failure: nil)
          repository_state.update!(
            "#{type}_verification_checksum" => checksum,
            "last_#{type}_verification_failure" => failure
          )
        end

        def repository_state
          @repository_state ||= project.repository_state || project.build_repository_state
        end

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
