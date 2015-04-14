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
        import_data = {
          "repo"      => repo.raw_data,
          "user_map"  => user_map
        }

        @project = Project.new(
          name: repo.name,
          path: repo.name,
          description: repo.summary,
          namespace: namespace,
          creator: current_user,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC,
          import_type: "google_code",
          import_source: repo.name,
          import_url: repo.import_url,
          import_data: import_data
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
