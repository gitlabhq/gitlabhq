module Gitlab
  module GoogleCodeImport
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
          description: repo.summary,
          namespace: namespace,
          creator: current_user,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC,
          import_type: "google_code",
          import_source: repo.name,
          import_url: repo.import_url,
          import_data: repo.raw_data
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
