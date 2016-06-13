module Gitlab
  module ImportExport
    class ProjectCreator

      def initialize(namespace_id, current_user, )
        @repo = repo
        @namespace = Namespace.find_by_id(namespace_id)
        @current_user = current_user
        @user_map = user_map
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: repo.name,
          path: repo.name,
          description: repo.summary,
          namespace: namespace,
          creator: current_user,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC,
          import_type: "google_code",
          import_source: repo.name,
          import_url: repo.import_url,
          import_data: { data: { 'repo' => repo.raw_data, 'user_map' => user_map } }
        ).execute
      end
    end
  end
end
