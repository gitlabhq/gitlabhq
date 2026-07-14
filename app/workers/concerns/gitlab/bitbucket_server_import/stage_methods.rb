# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module StageMethods
      extend ActiveSupport::Concern
      include ::Import::ResumableImportJob

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
        project = find_project(project_id)
        info(project_id, message: 'starting stage', Labkit::Fields::GL_ORGANIZATION_ID => project&.organization_id)

        return unless project&.import_state&.status == 'started'

        Import::RefreshImportJidWorker.perform_in_the_future(project_id, jid)

        import(project)

        info(project_id, message: 'stage finished', Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id)
      rescue BitbucketServer::Connection::ConnectionError => e
        raise if e.retryable?

        log_non_retryable_error(project_id, e, project)
      rescue StandardError => e
        track_and_raise(project_id, e)
      end

      def find_project(id)
        Project.find_by_id(id)
      end

      def abort_on_failure
        false
      end

      private

      def track_and_raise(project_id, exception)
        Gitlab::Import::ImportFailureService.track(
          project_id: project_id,
          exception: exception,
          error_source: self.class.name,
          fail_import: abort_on_failure
        )

        raise(exception)
      end

      def log_non_retryable_error(project_id, exception, project)
        Logger.warn(
          log_attributes(
            project_id,
            message: 'Non-retryable Bitbucket Server error, failing import',
            http_status_code: exception.http_status_code,
            error: exception.message,
            Labkit::Fields::GL_ORGANIZATION_ID => project&.organization_id
          )
        )

        Gitlab::Import::ImportFailureService.track(
          project_id: project_id,
          exception: exception,
          error_source: self.class.name,
          fail_import: true
        )
      end

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          import_stage: self.class.name
        ).compact
      end
    end
  end
end
