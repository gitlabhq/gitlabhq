# frozen_string_literal: true

module Gitlab
  module Import
    module StuckImportJob
      extend ActiveSupport::Concern

      StuckImportJobError = Class.new(StandardError)

      IMPORT_JOBS_EXPIRATION = 24.hours.seconds.to_i

      included do
        include ApplicationWorker

        # rubocop:disable Scalability/CronWorkerContext
        # This worker updates several import states inline and does not schedule
        # other jobs. So no context needed
        include CronjobQueue
        # rubocop:enable Scalability/CronWorkerContext

        feature_category :importers
        worker_resource_boundary :cpu
      end

      def perform
        stuck_imports_without_jid_count = mark_imports_without_jid_as_failed!
        stuck_imports_with_jid_count = mark_imports_with_jid_as_failed!

        track_metrics(stuck_imports_with_jid_count, stuck_imports_without_jid_count)
      end

      private

      def track_metrics(with_jid_count, without_jid_count)
        raise NotImplementedError
      end

      def mark_imports_without_jid_as_failed!
        enqueued_import_states_without_jid
          .each { |import_state| mark_as_failed(import_state) }
          .size
      end

      def mark_imports_with_jid_as_failed!
        jids_and_ids = enqueued_import_states_with_jid.pluck(:jid, :id).to_h # rubocop: disable CodeReuse/ActiveRecord

        # Find the jobs that aren't currently running or that exceeded the threshold.
        completed_jids = Gitlab::SidekiqStatus.completed_jids(jids_and_ids.keys)
        return 0 unless completed_jids.any?

        completed_import_state_ids = jids_and_ids.values_at(*completed_jids)

        # We select the import states again, because they may have transitioned from
        # scheduled/started to finished/failed while we were looking up their Sidekiq status.
        completed_import_states = enqueued_import_states_with_jid.id_in(completed_import_state_ids)
        completed_import_state_jids = completed_import_states.map { |import_state| import_state.jid }.join(', ')

        ::Import::Framework::Logger.info(
          message: 'Marked stuck import jobs as failed',
          job_ids: completed_import_state_jids
        )

        completed_import_states
          .each { |import_state| mark_as_failed(import_state) }
          .size
      end

      def mark_as_failed(import_state)
        raise StuckImportJobError, error_message
      rescue StuckImportJobError => e
        Gitlab::Import::ImportFailureService.track(
          import_state: import_state,
          exception: e,
          error_source: self.class.name,
          fail_import: true
        )
      end

      def enqueued_import_states
        raise NotImplementedError
      end

      def enqueued_import_states_with_jid
        enqueued_import_states.with_jid
      end

      def enqueued_import_states_without_jid
        enqueued_import_states.without_jid
      end

      def error_message
        _("Import timed out. Import took longer than %{import_jobs_expiration} seconds") % { import_jobs_expiration: IMPORT_JOBS_EXPIRATION }
      end
    end
  end
end
