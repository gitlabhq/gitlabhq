module EE
  module RepositoryCheck
    module SingleRepositoryWorker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :save_result
      def save_result(project, result)
        return super unless ::Gitlab::Geo.secondary?

        project_registry = ::Geo::ProjectRegistry.find_or_initialize_by(project: project)

        project_registry.assign_attributes(
          last_repository_check_failed: !result,
          last_repository_check_at: Time.now
        )
        project_registry.save!
      end
    end
  end
end
