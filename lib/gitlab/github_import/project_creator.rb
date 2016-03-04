module Gitlab
  module GithubImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user, :session_data

      def initialize(repo, namespace, current_user, session_data)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
      end

      def execute
        project = ::Projects::CreateService.new(
          current_user,
          name: repo.name,
          path: repo.name,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: repo.private ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::VisibilityLevel::PUBLIC,
          import_type: "github",
          import_source: repo.full_name,
          import_url: repo.clone_url,
          wiki_enabled: !repo.has_wiki? # If repo has wiki we'll import it later
        ).execute

        create_import_data(project)
        project
      end

      private

      def create_import_data(project)
        project.create_import_data(
          credentials: session_data.delete(:github_access_token),
          data: { "github_session" => session_data })
      end
    end
  end
end
