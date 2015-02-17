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
        @project = Project.new(
          name: repo["name"],
          path: repo["slug"],
          description: repo["description"],
          namespace: namespace,
          creator: current_user,
          visibility_level: repo["is_private"] ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::VisibilityLevel::PUBLIC,
          import_type: "bitbucket",
          import_source: "#{repo["owner"]}/#{repo["slug"]}",
          import_url: "ssh://git@bitbucket.org/#{repo["owner"]}/#{repo["slug"]}.git"
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
