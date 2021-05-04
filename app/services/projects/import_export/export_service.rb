# frozen_string_literal: true

module Projects
  module ImportExport
    class ExportService < BaseService
      prepend Measurable

      def initialize(*args)
        super

        @shared = project.import_export_shared
        @logger = Gitlab::Export::Logger.build
      end

      def execute(after_export_strategy = nil)
        unless project.template_source? || can?(current_user, :admin_project, project)
          raise ::Gitlab::ImportExport::Error.permission_error(current_user, project)
        end

        save_all!
        execute_after_export_action(after_export_strategy)
      ensure
        cleanup
      end

      protected

      def extra_attributes_for_measurement
        {
          current_user: current_user&.name,
          project_full_path: project&.full_path,
          file_path: shared.export_path
        }
      end

      private

      attr_accessor :shared

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
        [
          version_saver, avatar_saver, project_tree_saver, uploads_saver,
          repo_saver, wiki_repo_saver, lfs_saver, snippets_repo_saver, design_repo_saver
        ]
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
        Gitlab::ImportExport::RepoSaver.new(exportable: project, shared: shared)
      end

      def wiki_repo_saver
        Gitlab::ImportExport::WikiRepoSaver.new(exportable: project, shared: shared)
      end

      def lfs_saver
        Gitlab::ImportExport::LfsSaver.new(project: project, shared: shared)
      end

      def snippets_repo_saver
        Gitlab::ImportExport::SnippetsRepoSaver.new(current_user: current_user, project: project, shared: shared)
      end

      def design_repo_saver
        Gitlab::ImportExport::DesignRepoSaver.new(exportable: project, shared: shared)
      end

      def cleanup
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error, shared.errors.to_sentence
      end

      def notify_success
        @logger.info(
          message: 'Project successfully exported',
          project_name: project.name,
          project_id: project.id
        )
      end

      def notify_error
        @logger.error(
          message: 'Project export error',
          export_errors: shared.errors.join(', '),
          project_name: project.name,
          project_id: project.id
        )

        notification_service.project_not_exported(project, current_user, shared.errors)
      end
    end
  end
end
