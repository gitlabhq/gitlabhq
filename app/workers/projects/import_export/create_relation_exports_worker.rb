# frozen_string_literal: true

module Projects
  module ImportExport
    class CreateRelationExportsWorker
      include ApplicationWorker
      include ExceptionBacktrace

      idempotent!
      data_consistency :always
      deduplicate :until_executed, if_deduplicated: :reschedule_once
      feature_category :importers
      worker_resource_boundary :cpu
      sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

      # This delay is an arbitrary number to finish the export quicker in case all relations
      # are exported before the first execution of the WaitRelationExportsWorker worker.
      INITIAL_DELAY = 10.seconds

      RE_ENQUEUE_DELAY = 5.minutes

      # A job whose `updated_at` hasn't advanced in 30 minutes (6 re-enqueue cycles) is presumed
      # abandoned and excluded from the queue, so it can't hold a concurrency slot hostage until
      # StuckExportJobsWorker's next hourly run finally fails it.
      QUEUED_JOBS_EXPIRATION = RE_ENQUEUE_DELAY * 6

      def perform(user_id, project_id, after_export_strategy = {}, params = {})
        project = Project.find_by_id(project_id)
        return unless project

        params.symbolize_keys!

        project_export_job = find_or_create_project_export_job(project, user_id, params)
        return if project_export_job.started?

        if throttle_exports? && !next_in_queue?(project_export_job)
          return re_enqueue_job(user_id, project_id, after_export_strategy, params, project_export_job)
        end

        project_export_job.find_or_create_relation_exports!.each do |relation_export|
          RelationExportWorker.with_status.perform_async(relation_export.id, user_id, params)
        end

        project_export_job.start!

        WaitRelationExportsWorker.perform_in(
          INITIAL_DELAY,
          project_export_job.id,
          user_id,
          after_export_strategy
        )
      end

      private

      def throttle_exports?
        Feature.enabled?(:limit_concurrent_project_exports, :instance)
      end

      def find_or_create_project_export_job(project, user_id, params)
        exported_by_admin = !!params[:exported_by_admin]

        unless throttle_exports?
          return ProjectExportJob.find_or_create_by_jid(
            project, jid: jid, user_id: user_id, exported_by_admin: exported_by_admin
          )
        end

        ProjectExportJob.find_or_create_for(project, user_id, jid: jid, exported_by_admin: exported_by_admin)
      end

      def next_in_queue?(project_export_job)
        project_export_job.next_in_queue?(
          limit: ::Gitlab::CurrentSettings.concurrent_relation_export_limit,
          timeout: QUEUED_JOBS_EXPIRATION
        )
      end

      def re_enqueue_job(user_id, project_id, after_export_strategy, params, project_export_job)
        log_extra_metadata_on_done(:re_enqueue, true)

        new_jid = self.class.perform_in(RE_ENQUEUE_DELAY, user_id, project_id, after_export_strategy, params)
        return log_missing_re_enqueue(project_export_job) unless new_jid

        # StuckExportJobsWorker fails a queued job as soon as Gitlab::SidekiqStatus reports the
        # stored jid as completed, which happens when this execution returns. Pointing `jid` at the
        # scheduled job keeps a throttled export alive, as WaitRelationExportsWorker does for
        # started ones.
        project_export_job.update!(jid: new_jid)
      end

      def log_missing_re_enqueue(project_export_job)
        Gitlab::Export::Logger.error(
          message: 'Throttled project export was not re-enqueued',
          project_export_job_id: project_export_job.id,
          project_id: project_export_job.project_id
        )
      end
    end
  end
end
