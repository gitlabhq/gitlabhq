# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module StageMethods
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        worker_has_external_dependencies!

        feature_category :importers

        data_consistency :always

        sidekiq_options dead: false, retry: 6

        sidekiq_options status_expiration: Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION

        sidekiq_retries_exhausted do |msg, e|
          Gitlab::Import::ImportFailureService.track(
            project_id: msg['args'][0],
            exception: e,
            fail_import: true
          )
        end
      end

      # project_id - The ID of the GitLab project to import the data into.
      def perform(project_id)
        info(project_id, message: 'starting stage')

        return unless (project = find_project(project_id))

        Import::RefreshImportJidWorker.perform_in_the_future(project_id, jid)

        import(project)

        info(project_id, message: 'stage finished')
      rescue StandardError => e
        Gitlab::Import::ImportFailureService.track(
          project_id: project_id,
          exception: e,
          error_source: self.class.name,
          fail_import: abort_on_failure
        )

        raise(e)
      end

      def find_project(id)
        # If the project has been marked as failed we want to bail out
        # automatically.
        # rubocop: disable CodeReuse/ActiveRecord
        Project.joins_import_state.where(import_state: { status: :started }).find_by_id(id)
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def abort_on_failure
        false
      end

      private

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          import_stage: self.class.name
        )
      end
    end
  end
end
