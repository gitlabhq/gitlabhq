# frozen_string_literal: true

module Gitlab
  module GithubImport
    module StageMethods
      # project_id - The ID of the GitLab project to import the data into.
      def perform(project_id)
        info(project_id, message: 'starting stage')

        return unless (project = find_project(project_id))

        if project.import_state&.canceled?
          info(project_id, message: 'project import canceled')

          return
        end

        client = GithubImport.new_client_for(project)

        try_import(client, project)

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

      # client - An instance of Gitlab::GithubImport::Client.
      # project - An instance of Project.
      def try_import(client, project)
        import(client, project)
      rescue RateLimitError
        self.class.perform_in(client.rate_limit_resets_in, project.id)
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
        Gitlab::GithubImport::Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          import_stage: self.class.name
        )
      end

      def import_settings(project)
        Gitlab::GithubImport::Settings.new(project)
      end
    end
  end
end
