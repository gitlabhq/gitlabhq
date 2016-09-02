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
          visibility_level: repo.private ? Gitlab::VisibilityLevel::PRIVATE : ApplicationSetting.current.default_project_visibility,
          import_type: "github",
          import_source: repo.full_name,
          import_url: repo.clone_url.sub("https://", "https://#{@session_data[:github_access_token]}@")
        ).execute

        # If repo has wiki we'll import it later
        if repo.has_wiki? && project
          project.project_feature.update_attribute(:wiki_access_level, ProjectFeature::DISABLED)
        end

        project
      end
    end
  end
end
