module Gitlab
  module ImportExport
    class ImportService

      def self.execute(*args)
        new(*args).execute
      end

      def initialize(archive_file:, owner:, namespace_id:, project_path:)
        @archive_file = archive_file
        @current_user = owner
        @namespace = Namespace.find(namespace_id)
        @shared = Gitlab::ImportExport::Shared.new(relative_path: path_with_namespace, project_path: project_path)
      end

      def execute
        Gitlab::ImportExport::Importer.import(archive_file: @archive_file,
                                              shared: @shared)
        project_tree.project if [restore_project_tree, restore_repo, restore_wiki_repo].all?
      end

      private

      def restore_project_tree
        project_tree.restore
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(user: @current_user,
                                                                        shared: @shared,
                                                                        namespace_id: @namespace.id)
      end

      def restore_repo
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                               shared: @shared,
                                               project: project_tree.project).restore
      end

      def restore_wiki_repo
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: wiki_repo_path,
                                               shared: @shared,
                                               project: ProjectWiki.new(project_tree.project)).restore
      end

      def path_with_namespace
        File.join(@namespace.path, @shared.opts[:project_path])
      end

      def repo_path
        File.join(@shared.export_path, 'project.bundle')
      end

      def wiki_repo_path
        File.join(@shared.export_path, 'project.wiki.bundle')
      end
    end
  end
end
