# frozen_string_literal: true

module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(after_export_strategy = nil, options = {})
        unless project.template_source? || can?(current_user, :admin_project, project)
          raise ::Gitlab::ImportExport::Error.permission_error(current_user, project)
        end

        @shared = project.import_export_shared

        measurement_enabled = !!options[:measurement_enabled]
        measurement_logger = options[:measurement_logger]

        ::Gitlab::Utils::Measuring.execute_with(measurement_enabled, measurement_logger, base_log_data) do
          save_all!
          execute_after_export_action(after_export_strategy)
        end
      ensure
        cleanup
      end

      private

      attr_accessor :shared

      def base_log_data
        {
          class: self.class.name,
          current_user: current_user.name,
          project_full_path: project.full_path,
          file_path: shared.export_path
        }
      end

      def execute_after_export_action(after_export_strategy)
        return unless after_export_strategy

        unless after_export_strategy.execute(current_user, project)
          notify_error
        end
      end

      def save_all!
        if save_exporters
          Gitlab::ImportExport::Saver.save(exportable: project, shared: shared)
          notify_success
        else
          notify_error!
        end
      end

      def save_exporters
        exporters.all?(&:save)
      end

      def exporters
        [version_saver, avatar_saver, project_tree_saver, uploads_saver, repo_saver, wiki_repo_saver, lfs_saver, snippets_repo_saver]
      end

      def version_saver
        Gitlab::ImportExport::VersionSaver.new(shared: shared)
      end

      def avatar_saver
        Gitlab::ImportExport::AvatarSaver.new(project: project, shared: shared)
      end

      def project_tree_saver
        tree_saver_class.new(project: project, current_user: current_user, shared: shared, params: params)
      end

      def tree_saver_class
        Gitlab::ImportExport::Project::TreeSaver
      end

      def uploads_saver
        Gitlab::ImportExport::UploadsSaver.new(project: project, shared: shared)
      end

      def repo_saver
        Gitlab::ImportExport::RepoSaver.new(project: project, shared: shared)
      end

      def wiki_repo_saver
        Gitlab::ImportExport::WikiRepoSaver.new(project: project, shared: shared)
      end

      def lfs_saver
        Gitlab::ImportExport::LfsSaver.new(project: project, shared: shared)
      end

      def snippets_repo_saver
        Gitlab::ImportExport::SnippetsRepoSaver.new(current_user: current_user, project: project, shared: shared)
      end

      def cleanup
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error.new(shared.errors.to_sentence)
      end

      def notify_success
        Rails.logger.info("Import/Export - Project #{project.name} with ID: #{project.id} successfully exported") # rubocop:disable Gitlab/RailsLogger
      end

      def notify_error
        Rails.logger.error("Import/Export - Project #{project.name} with ID: #{project.id} export error - #{shared.errors.join(', ')}") # rubocop:disable Gitlab/RailsLogger

        notification_service.project_not_exported(project, current_user, shared.errors)
      end
    end
  end
end

Projects::ImportExport::ExportService.prepend_if_ee('EE::Projects::ImportExport::ExportService')
