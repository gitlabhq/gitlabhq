module EE
  module RepositoryCheck
    module SingleRepositoryWorker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :update_repository_check_status
      def update_repository_check_status(project, healthy)
        return super unless ::Gitlab::Geo.secondary?

        project_registry = ::Geo::ProjectRegistry.find_or_initialize_by(project: project)

        project_registry.assign_attributes(
          last_repository_check_failed: !healthy,
          last_repository_check_at: Time.zone.now
        )
        project_registry.save!
      end
    end
  end
end
