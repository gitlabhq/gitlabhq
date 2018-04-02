module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(after_export_strategy = nil, options = {})
        @shared = project.import_export_shared

        save_all!
        execute_after_export_action(after_export_strategy)
      end

      private

      def execute_after_export_action(after_export_strategy)
        return unless after_export_strategy

        unless after_export_strategy.execute(current_user, project)
          cleanup_and_notify_error
        end
      end

      def save_all!
        if save_services
          Gitlab::ImportExport::Saver.save(project: project, shared: @shared)
          notify_success
        else
          cleanup_and_notify_error!
        end
      end

      def save_services
        [version_saver, avatar_saver, project_tree_saver, uploads_saver, repo_saver, wiki_repo_saver].all?(&:save)
      end

      def version_saver
        Gitlab::ImportExport::VersionSaver.new(shared: @shared)
      end

      def avatar_saver
        Gitlab::ImportExport::AvatarSaver.new(project: project, shared: @shared)
      end

      def project_tree_saver
        Gitlab::ImportExport::ProjectTreeSaver.new(project: project, current_user: @current_user, shared: @shared, params: @params)
      end

      def uploads_saver
        Gitlab::ImportExport::UploadsSaver.new(project: project, shared: @shared)
      end

      def repo_saver
        Gitlab::ImportExport::RepoSaver.new(project: project, shared: @shared)
      end

      def wiki_repo_saver
        Gitlab::ImportExport::WikiRepoSaver.new(project: project, shared: @shared)
      end

      def cleanup_and_notify_error
        Rails.logger.error("Import/Export - Project #{project.name} with ID: #{project.id} export error - #{@shared.errors.join(', ')}")

        FileUtils.rm_rf(@shared.export_path)

        notify_error
      end

      def cleanup_and_notify_error!
        cleanup_and_notify_error

        raise Gitlab::ImportExport::Error.new(@shared.errors.join(', '))
      end

      def notify_success
        Rails.logger.info("Import/Export - Project #{project.name} with ID: #{project.id} successfully exported")
      end

      def notify_error
        notification_service.project_not_exported(@project, @current_user, @shared.errors)
      end
    end
  end
end
