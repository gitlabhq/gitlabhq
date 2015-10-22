module Gitlab
  module GoogleCodeImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user, :user_map

      def initialize(repo, namespace, current_user, user_map = nil)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
        @user_map = user_map
      end

      def execute
        project = ::Projects::CreateService.new(current_user,
          name: repo.name,
          path: repo.name,
          description: repo.summary,
          namespace: namespace,
          creator: current_user,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC,
          import_type: "google_code",
          import_source: repo.name,
          import_url: repo.import_url
        ).execute

        project.create_import_data(
          data: {
            "repo"      => repo.raw_data,
            "user_map"  => user_map
          }
        )

        project
      end
    end
  end
end
