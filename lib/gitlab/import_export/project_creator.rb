module Gitlab
  module ImportExport
    class ProjectCreator
      def initialize(namespace_id, current_user, file, project_path)
        @namespace_id = namespace_id
        @current_user = current_user
        @file = file
        @project_path = project_path
      end

      def execute
        ::Projects::CreateService.new(
          @current_user,
          name: @project_path,
          path: @project_path,
          namespace_id: @namespace_id,
          import_type: "gitlab_project",
          import_source: @file
        ).execute
      end
    end
  end
end
