module Gitlab
  module ImportExport
    class ImportService

      def self.execute(*args)
        new(args).execute
      end

      def initialize(options = {})
        @archive_file = options[:archive_file]
        @current_user = options[:owner]
      end

      def execute
        Gitlab::ImportExport::Importer.import(archive_file: @archive_file, storage_path: storage_path)
        restore_project_tree
        restore_repo(project_tree.project)
      end

      private

      def restore_project_tree
        project_tree.restore
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(path: storage_path, user: @current_user)
      end

      def restore_repo(project)
        Gitlab::ImportExport::RepoRestorer.new(path: storage_path, project: project).restore
      end

      def storage_path
        @storage_path ||= Gitlab::ImportExport.export_path(relative_path: project.path_with_namespace)
      end
    end
  end
end
