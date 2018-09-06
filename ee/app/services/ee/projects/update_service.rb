module EE
  module Projects
    module UpdateService
      extend ::Gitlab::Utils::Override
      include ValidatesClassificationLabel
      include CleanupApprovers

      override :execute
      def execute
        should_remove_old_approvers = params.delete(:remove_old_approvers)
        wiki_was_enabled = project.wiki_enabled?

        limit = params.delete(:repository_size_limit)

        unless valid_mirror_user?
          project.errors.add(:mirror_user_id, 'is invalid')
          return project
        end

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

      def valid_mirror_user?
        return true unless params[:mirror_user_id].present?

        mirror_user_id = params[:mirror_user_id].to_i

        mirror_user_id == current_user.id ||
          mirror_user_id == project.mirror_user&.id
      end

      def log_audit_events
        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute
      end

      def sync_wiki_on_enable
        ::Geo::RepositoryUpdatedService.new(project.wiki.repository).execute
      end
    end
  end
end
