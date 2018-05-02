module EE
  module RepositoryCheck
    module SingleRepositoryWorker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :save_result
      def save_result(project, failure)
        # TODO: Check for Geo

        # TODO: What if project registry does not exist

        project_registry = Geo::ProjectRegistry.find_by(project_id: project.id)

        project_registry.update_columns(
          last_repository_check_failed: failure,
          last_repository_check_at: Time.now
        )
      end
    end
  end
end
