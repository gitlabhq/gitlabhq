module EE
  module Projects
    module UpdateService
      extend ::Gitlab::Utils::Override

      include CleanupApprovers

      override :execute
      def execute
        unless project.feature_available?(:repository_mirrors)
          params.delete(:mirror)
          params.delete(:mirror_user_id)
          params.delete(:mirror_trigger_builds)
        end

        should_remove_old_approvers = params.delete(:remove_old_approvers)
        wiki_was_enabled = project.wiki_enabled?

        result = super

        if result[:status] == :success
          cleanup_approvers(project) if should_remove_old_approvers

          log_audit_events

          sync_wiki_on_enable if !wiki_was_enabled && project.wiki_enabled?
        end

        result
      end

      def changing_storage_size?
        new_repository_storage = params[:repository_storage]

        new_repository_storage && project.repository.exists? &&
          can?(current_user, :change_repository_storage, project)
      end

      private

      def log_audit_events
        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute
      end

      def sync_wiki_on_enable
        ::Geo::RepositoryUpdatedService.new(project, source: ::Geo::RepositoryUpdatedEvent::WIKI).execute
      end
    end
  end
end
