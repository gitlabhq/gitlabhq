module Gitlab
  module BitbucketImport
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
          path: repo["slug"],
          description: repo["description"],
          namespace_id: namespace.id,
          visibility_level: repo["is_private"] ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::VisibilityLevel::PUBLIC,
          import_type: "bitbucket",
          import_source: "#{repo["owner"]}/#{repo["slug"]}",
          import_url: "ssh://git@bitbucket.org/#{repo["owner"]}/#{repo["slug"]}.git",
        ).execute

        import_data = project.import_data
        # merge! with a bang doesn't work here
        import_data.credentials = import_data.credentials.merge(bb_session: session_data)
        import_data.save

        project
      end
    end
  end
end
