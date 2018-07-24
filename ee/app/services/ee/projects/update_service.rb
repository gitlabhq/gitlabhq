module EE
  module Projects
    module UpdateService
      extend ::Gitlab::Utils::Override
      include ValidatesClassificationLabel
      include CleanupApprovers

      override :execute
      def execute
        unless project.feature_available?(:repository_mirrors)
          params.delete(:mirror)
          params.delete(:mirror_user_id)
          params.delete(:mirror_trigger_builds)
          params.delete(:only_mirror_protected_branches)
          params.delete(:mirror_overwrites_diverged_branches)
          params.delete(:import_data_attributes)
        end

        should_remove_old_approvers = params.delete(:remove_old_approvers)
        wiki_was_enabled = project.wiki_enabled?

        limit = params.delete(:repository_size_limit)
        result = super do
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if changing_storage_size?
            project.change_repository_storage(params.delete(:repository_storage))
          end

          validate_classification_label(project, :external_authorization_classification_label)
        end

        if result[:status] == :success
          cleanup_approvers(project) if should_remove_old_approvers

          log_audit_events

          sync_wiki_on_enable if !wiki_was_enabled && project.wiki_enabled?
          project.force_import_job! if params[:mirror].present? && project.mirror?
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
