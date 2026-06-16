# frozen_string_literal: true

module Gitlab
  module GithubImport
    module StageMethods
      extend ActiveSupport::Concern
      include ::Import::ResumableImportJob

      included do
        include ApplicationWorker
        include GithubImport::Queue

        sidekiq_options retry: 6

        sidekiq_options status_expiration: Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION

        sidekiq_retries_exhausted do |msg, e|
          Gitlab::Import::ImportFailureService.track(
            project_id: msg['args'][0],
            exception: e,
            error_source: self.class.name,
            fail_import: true
          )
        end
      end

      # project_id - The ID of the GitLab project to import the data into.
      def perform(project_id)
        project = Project.find_by_id(project_id)
        info(project_id, message: 'starting stage', Labkit::Fields::GL_ORGANIZATION_ID => project&.organization_id)

        return unless project

        if project.import_state&.completed?
          info(
            project_id,
            message: 'Project import is no longer running. Stopping worker.',
            import_status: project.import_state.status,
            Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id
          )

          return
        end

        Import::RefreshImportJidWorker.perform_in_the_future(project.id, jid)

        client = GithubImport.new_client_for(project)

        try_import(client, project)
      rescue StandardError => e
        Gitlab::Import::ImportFailureService.track(
          project_id: project_id,
          exception: e,
          error_source: self.class.name,
          fail_import: false,
          metrics: true
        )

        raise(e)
      end

      private

      # client - An instance of Gitlab::GithubImport::Client.
      # project - An instance of Project.
      def try_import(client, project)
        import(client, project)

        info(project.id, message: 'stage finished', Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id)
      rescue RateLimitError, UserFinder::FailedToObtainLockError => e
        info(
          project.id,
          message: "stage retrying",
          exception_class: e.class.name,
          Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id
        )

        rate_limit_resets_in = e.try(:reset_in) || client.rate_limit_resets_in
        self.class.perform_in(rate_limit_resets_in, project.id)
      end

      def info(project_id, extra = {})
        Gitlab::GithubImport::Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          import_stage: self.class.name
        ).compact
      end

      def import_settings(project)
        Gitlab::GithubImport::Settings.new(project)
      end
    end
  end
end
