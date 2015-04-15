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
        ::Projects::CreateService.new(current_user,
          name: repo["name"],
          path: repo["path"],
          description: repo["description"],
          namespace_id: namespace.id,
          visibility_level: repo["visibility_level"],
          import_type: "gitlab",
          import_source: repo["path_with_namespace"],
          import_url: repo["http_url_to_repo"].sub("://", "://oauth2:#{current_user.gitlab_access_token}@")
        ).execute
      end
    end
  end
end
