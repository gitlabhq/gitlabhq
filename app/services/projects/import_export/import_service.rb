module Projects
  module ImportExport
    class ExportService < BaseService
      def execute(options = {})
        @import_path = options[:import_path]
      end

      private

      def restore_project_tree
        Projects::ImportExport::ProjectTreeRestorer.new(path: @import_path).restore
      end

      def restore_repo

      end
    end
  end
end
