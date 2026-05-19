# frozen_string_literal: true

module Gitlab
  module BitbucketImport
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

        project = find_project(project_id)

        return unless project

        Import::RefreshImportJidWorker.perform_in_the_future(project_id, jid)

        import(project)

        info(project_id, message: 'stage finished')
      rescue OAuth2::Error => e
        fail_import_for_non_retryable_error(project_id, e)
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

      GONE_MESSAGE = 'The requested resource is no longer available. The repository may have been deleted ' \
        'or the issue tracker may have been disabled on the source.'

      def abort_on_failure
        false
      end

      private

      def fail_import_for_non_retryable_error(project_id, exception)
        http_status = exception.response.try(:status)
        error_message = bitbucket_error_message(exception, http_status)

        Gitlab::Import::ImportFailureService.track(
          project_id: project_id,
          exception: StandardError.new(error_message),
          error_source: self.class.name,
          fail_import: true,
          message: 'import failed due to a non-retryable Bitbucket API error',
          extra_attributes: { http_status_code: http_status }.compact
        )
      end

      def bitbucket_error_message(exception, http_status = exception.response.try(:status))
        return GONE_MESSAGE if http_status == 410

        parsed = Gitlab::Json.safe_parse(exception.body)
        message = parsed.dig('error', 'message') if parsed.is_a?(Hash)

        message || exception.message
      rescue JSON::ParserError
        exception.message
      end

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
