# frozen_string_literal: true

module Projects
  module ImportExport
    class ExportService < BaseService
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

      def exporters
        [
          version_saver, avatar_saver, project_tree_saver, uploads_saver,
          repo_saver, wiki_repo_saver, lfs_saver, snippets_repo_saver, design_repo_saver
        ]
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
      attr_reader :logger

      def execute_after_export_action(after_export_strategy)
        return unless after_export_strategy

        unless after_export_strategy.execute(current_user, project)
          notify_error
        end
      end

      def save_all!
        log_info('Project export started')

        if save_exporters && save_export_archive
          log_info('Project successfully exported')
        else
          notify_error!
        end
      end

      def save_exporters
        exporters.all? do |exporter|
          log_info("#{exporter.class.name} saver started")

          exporter.save
        end
      end

      def save_export_archive
        @export_saver ||= Gitlab::ImportExport::Saver.save(exportable: project, shared: shared, user: current_user)
      end

      def version_saver
        @version_saver ||= Gitlab::ImportExport::VersionSaver.new(shared: shared)
      end

      def avatar_saver
        @avatar_saver ||= Gitlab::ImportExport::AvatarSaver.new(project: project, shared: shared)
      end

      def project_tree_saver
        @project_tree_saver ||= tree_saver_class.new(
          project: project,
          current_user: current_user,
          shared: shared,
          params: params,
          logger: logger)
      end

      def tree_saver_class
        Gitlab::ImportExport::Project::TreeSaver
      end

      def uploads_saver
        @uploads_saver ||= Gitlab::ImportExport::UploadsSaver.new(project: project, shared: shared)
      end

      def repo_saver
        @repo_saver ||= Gitlab::ImportExport::RepoSaver.new(exportable: project, shared: shared)
      end

      def wiki_repo_saver
        @wiki_repo_saver ||= Gitlab::ImportExport::WikiRepoSaver.new(exportable: project, shared: shared)
      end

      def lfs_saver
        @lfs_saver ||= Gitlab::ImportExport::LfsSaver.new(project: project, shared: shared)
      end

      def snippets_repo_saver
        @snippets_repo_saver ||= Gitlab::ImportExport::SnippetsRepoSaver.new(
          current_user: current_user,
          project: project,
          shared: shared
        )
      end

      def design_repo_saver
        @design_repo_saver ||= Gitlab::ImportExport::DesignRepoSaver.new(exportable: project, shared: shared)
      end

      def cleanup
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error, shared.errors.to_sentence
      end

      def log_info(message)
        logger.info(
          message: message,
          **log_base_data
        )
      end

      def notify_error
        logger.error(
          message: 'Project export error',
          export_errors: shared.errors.join(', '),
          **log_base_data
        )

        user = current_user
        errors = shared.errors

        project.run_after_commit_or_now do |project|
          NotificationService.new.project_not_exported(project, user, errors)
        end
      end

      def log_base_data
        @log_base_data ||= Gitlab::ImportExport::LogUtil.exportable_to_log_payload(project)
      end
    end
  end
end
