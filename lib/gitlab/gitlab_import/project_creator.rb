module Gitlab
  module GitlabImport
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
          name: repo["name"],
          path: repo["path"],
          description: repo["description"],
          namespace_id: namespace.id,
          visibility_level: repo["visibility_level"],
          import_type: "gitlab",
          import_source: repo["path_with_namespace"],
          import_url: repo["http_url_to_repo"].sub("://", "://oauth2:#{@session_data[:gitlab_access_token]}@")
        ).execute

        project.create_import_data(data: { "gitlab_session" => session_data } )
        project
      end
    end
  end
end
