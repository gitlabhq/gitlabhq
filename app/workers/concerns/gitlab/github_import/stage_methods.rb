# frozen_string_literal: true

module Gitlab
  module GithubImport
    module StageMethods
      # project_id - The ID of the GitLab project to import the data into.
      def perform(project_id)
        return unless (project = find_project(project_id))

        client = GithubImport.new_client_for(project)

        try_import(client, project)
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
        Project.import_started.find_by(id: id)
      end
    end
  end
end
