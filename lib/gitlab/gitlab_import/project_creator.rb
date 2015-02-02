module Gitlab
  module GitlabImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user

      def initialize(repo, namespace, current_user)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
      end

      def execute
        @project = Project.new(
          name: repo["name"],
          path: repo["path"],
          description: repo["description"],
          namespace: namespace,
          creator: current_user,
          visibility_level: repo["visibility_level"],
          import_type: "gitlab",
          import_source: repo["path_with_namespace"],
          import_url: repo["http_url_to_repo"].sub("://", "://oauth2:#{current_user.gitlab_access_token}@")
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
