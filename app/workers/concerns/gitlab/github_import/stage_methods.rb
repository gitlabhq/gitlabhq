# frozen_string_literal: true

module Gitlab
  module GithubImport
    module StageMethods
      # project_id - The ID of the GitLab project to import the data into.
      def perform(project_id)
        info(project_id, message: 'starting stage')

        return unless (project = find_project(project_id))

        client = GithubImport.new_client_for(project)

        try_import(client, project)

        info(project_id, message: 'stage finished')
      rescue StandardError => e
        error(project_id, e)
      end

      # client - An instance of Gitlab::GithubImport::Client.
      # project - An instance of Project.
      def try_import(client, project)
        import(client, project)
      rescue RateLimitError
        self.class.perform_in(client.rate_limit_resets_in, project.id)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_project(id)
        # If the project has been marked as failed we want to bail out
        # automatically.
        Project.joins_import_state.where(import_state: { status: :started }).find_by(id: id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def info(project_id, extra = {})
        logger.info(log_attributes(project_id, extra))
      end

      def error(project_id, exception)
        logger.error(
          log_attributes(
            project_id,
            message: 'stage failed',
            'error.message': exception.message
          )
        )

        Gitlab::ErrorTracking.track_and_raise_exception(
          exception,
          log_attributes(project_id)
        )
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          import_source: :github,
          project_id: project_id,
          import_stage: self.class.name
        )
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
