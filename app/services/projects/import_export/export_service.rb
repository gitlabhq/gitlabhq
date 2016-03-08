module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(options = {})
        @shared = Projects::ImportExport::Shared.new(relative_path: project.path_with_namespace)
        save_project_tree
        bundle_repo
      end

      private

      def save_project_tree
        Projects::ImportExport::ProjectTreeSaver.new(project: project, shared: @shared).save
      end

      def bundle_repo
        Projects::ImportExport::RepoBundler.new(project: project, shared: @shared).bundle
      end
    end
  end
end
