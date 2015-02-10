module Gitlab
  module GithubImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user

      def initialize(repo, namespace, current_user)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
      end

      def execute
        @project = Project.new(
          name: repo.name,
          path: repo.name,
          description: repo.description,
          namespace: namespace,
          creator: current_user,
          visibility_level: repo.private ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::VisibilityLevel::PUBLIC,
          import_type: "github",
          import_source: repo.full_name,
          import_url: repo.clone_url.sub("https://", "https://#{current_user.github_access_token}@")
        )

        if @project.save!
          @project.reload

          if @project.import_failed?
            @project.import_retry
          else
            @project.import_start
          end
        end

        @project
      end
    end
  end
end
