# frozen_string_literal: true

module Projects
  module ImportExport
    class WaitRelationExportsWorker
      include ApplicationWorker
      include ExceptionBacktrace

      idempotent!
      data_consistency :always
      feature_category :importers
      loggable_arguments 1, 2
      worker_resource_boundary :cpu
      sidekiq_options dead: false, status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

      INTERVAL = 1.minute

      def perform(project_export_job_id, user_id, after_export_strategy = {})
        @export_job = ProjectExportJob.find(project_export_job_id)

        return unless @export_job.started?

        @export_job.update_attribute(:jid, jid)
        @relation_exports = @export_job.relation_exports

        if queued_relation_exports.any? || started_relation_exports.any?
          fail_started_jobs_no_longer_running

          self.class.perform_in(INTERVAL, project_export_job_id, user_id, after_export_strategy)
          return
        end

        if all_relation_export_finished?
          ParallelProjectExportWorker.perform_async(project_export_job_id, user_id, after_export_strategy)
          return
        end

        fail_and_notify_user(user_id)
      end

      private

      def relation_exports_with_status(status)
        @relation_exports.select { |relation_export| relation_export.status == status }
      end

      def queued_relation_exports
        relation_exports_with_status(RelationExport::STATUS[:queued])
      end

      def started_relation_exports
        @started_relation_exports ||= relation_exports_with_status(RelationExport::STATUS[:started])
      end

      def all_relation_export_finished?
        @relation_exports.all? { |relation_export| relation_export.status == RelationExport::STATUS[:finished] }
      end

      def fail_started_jobs_no_longer_running
        started_relation_exports.each do |relation_export|
          next if Gitlab::SidekiqStatus.running?(relation_export.jid)
          next if relation_export.reset.finished?

          relation_export.mark_as_failed("Exhausted number of retries to export: #{relation_export.relation}")
        end
      end

      def fail_and_notify_user(user_id)
        @export_job.fail_op!

        @user = User.find_by_id(user_id)
        return unless @user

        failed_relation_exports = relation_exports_with_status(RelationExport::STATUS[:failed])
        errors = failed_relation_exports.map(&:export_error)

        NotificationService.new.project_not_exported(@export_job.project, @user, errors)
      end
    end
  end
end
