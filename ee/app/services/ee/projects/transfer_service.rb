module EE
  module Projects
    module TransferService
      private

      def execute_system_hooks
        raise NotImplementedError unless defined?(super)

        super

        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute

        ::Geo::RepositoryRenamedEventStore.new(
          project,
          old_path: project.path,
          old_path_with_namespace: @old_path # rubocop:disable Gitlab/ModuleWithInstanceVariables
        ).create
      end
    end
  end
end
