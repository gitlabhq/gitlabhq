# frozen_string_literal: true

module Projects
  module ImportExport
    class ParallelExportService
      def initialize(export_job, current_user, after_export_strategy)
        @export_job = export_job
        @current_user = current_user
        @after_export_strategy = after_export_strategy
        @shared = project.import_export_shared
        @logger = Gitlab::Export::Logger.build
      end

      def execute
        log_info('Parallel project export started')

        if save_exporters && save_export_archive
          log_info('Parallel project export finished successfully')
          execute_after_export_action(after_export_strategy)
        else
          notify_error
        end

      ensure
        cleanup
      end

      private

      attr_reader :export_job, :current_user, :after_export_strategy, :shared, :logger

      delegate :project, to: :export_job

      def execute_after_export_action(after_export_strategy)
        return if after_export_strategy.execute(current_user, project)

        notify_error
      end

      def exporters
        [version_saver, exported_relations_merger]
      end

      def save_exporters
        exporters.all? do |exporter|
          log_info("Parallel project export - #{exporter.class.name} saver started")

          exporter.save
        end
      end

      def save_export_archive
        Gitlab::ImportExport::Saver.save(exportable: project, shared: shared, user: current_user)
      end

      def version_saver
        @version_saver ||= Gitlab::ImportExport::VersionSaver.new(shared: shared)
      end

      def exported_relations_merger
        @relation_saver ||= Gitlab::ImportExport::Project::ExportedRelationsMerger.new(
          export_job: export_job,
          shared: shared)
      end

      def cleanup
        FileUtils.rm_rf(shared.export_path)
        FileUtils.rm_rf(shared.archive_path)
      end

      def log_info(message)
        logger.info(
          message: message,
          **log_base_data
        )
      end

      def notify_error
        logger.error(
          message: 'Parallel project export error',
          export_errors: shared.errors.join(', '),
          export_job_id: export_job.id,
          **log_base_data
        )

        NotificationService.new.project_not_exported(project, current_user, shared.errors)
      end

      def log_base_data
        {
          project_id: project.id,
          project_name: project.name,
          project_path: project.full_path
        }
      end
    end
  end
end
