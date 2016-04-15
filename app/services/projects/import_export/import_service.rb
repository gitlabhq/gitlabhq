module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(options = {})

        @import_path = options[:import_path]
        restore_project_tree
        restore_repo(project_tree.project)
      end

      private

      def restore_project_tree
        project_tree.restore
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(path: @import_path, user: @current_user)
      end

      def restore_repo(project)
        Gitlab::ImportExport::RepoRestorer.new(path: @import_path, project: project).restore
      end
    end
  end
end
