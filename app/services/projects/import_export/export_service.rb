module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(options = {})
        save_project_tree
      end

      private

      def save_project_tree
        Projects::ImportExport::ProjectTreeSaver.save(project: project)
      end
    end
  end
end
