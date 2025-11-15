# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExportWorker
      include ApplicationWorker
      include ExceptionBacktrace
      include Sidekiq::InterruptionsExhausted

      MAX_INTERRUPTIONS_ERROR_MESSAGE = 'Relation export process reached the maximum number of interruptions'

      idempotent!
      data_consistency :always
      deduplicate :until_executed
      feature_category :importers
      sidekiq_options dead: false, status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION, retry: 6
      urgency :low
      worker_resource_boundary :memory
      tags :import_shared_storage
      max_concurrency_limit_percentage 0.75

      sidekiq_retries_exhausted do |job, exception|
        project_relation_export_id = job['args'].first
        relation_export = find_relation_export(project_relation_export_id)
        next unless relation_export

        new.mark_relation_export_failed!(relation_export, job['error_message'], exception: exception)
      end

      sidekiq_interruptions_exhausted do |job|
        project_relation_export_id = job['args'].first
        relation_export = find_relation_export(project_relation_export_id)
        next unless relation_export

        exception = ::Import::Exceptions::SidekiqExhaustedInterruptionsError.new(MAX_INTERRUPTIONS_ERROR_MESSAGE)
        message = "#{MAX_INTERRUPTIONS_ERROR_MESSAGE} while exporting #{relation_export.relation}"
        new.mark_relation_export_failed!(relation_export, message, exception: exception)
      end

      def self.find_relation_export(project_relation_export_id)
        Projects::ImportExport::RelationExport.find_by_id(project_relation_export_id)
      end

      def perform(project_relation_export_id, user_id, params = {})
        user = User.find_by_id(user_id)
        return unless user

        relation_export = self.class.find_relation_export(project_relation_export_id)
        return unless relation_export

        log_extra_metadata_on_done(:relation, relation_export.relation)

        return if user_banned?(user, user_id, relation_export)

        relation_export.retry! if relation_export.started?

        if relation_export.queued?
          Projects::ImportExport::RelationExportService.new(relation_export, user, jid, params.symbolize_keys).execute
        end
      end

      def mark_relation_export_failed!(relation_export, message, exception: nil)
        project_export_job = relation_export.project_export_job
        project = project_export_job.project

        relation_export.mark_as_failed(message)

        log_payload = {
          message: 'Project relation export failed',
          export_error: message,
          relation: relation_export.relation,
          project_export_job_id: project_export_job.id,
          project_name: project.name,
          project_id: project.id
        }

        Gitlab::ExceptionLogFormatter.format!(exception, log_payload) if exception.present?
        Gitlab::Export::Logger.error(log_payload)
      end

      private

      def user_banned?(user, user_id, relation_export)
        return false unless user.banned?

        mark_relation_export_failed!(relation_export, "User #{user_id} is banned")
        true
      end
    end
  end
end
