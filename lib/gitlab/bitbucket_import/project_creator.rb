module Gitlab
  module BitbucketImport
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
          path: repo["slug"],
          description: repo["description"],
          namespace_id: namespace.id,
          visibility_level: repo["is_private"] ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::VisibilityLevel::PUBLIC,
          import_type: "bitbucket",
          import_source: "#{repo["owner"]}/#{repo["slug"]}",
          import_url: "ssh://git@bitbucket.org/#{repo["owner"]}/#{repo["slug"]}.git"
        ).execute
      end
    end
  end
end
