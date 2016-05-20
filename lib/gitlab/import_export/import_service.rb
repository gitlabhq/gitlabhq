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
        @shared = Gitlab::ImportExport::Shared.new(relative_path: path_with_namespace(project_path), project_path: project_path)
      end

      def execute
        Gitlab::ImportExport::Importer.import(archive_file: @archive_file,
                                              shared: @shared)
        if [restore_version, restore_project_tree, restore_repo, restore_wiki_repo, restore_uploads].all?
          Todo.create(attributes_for_todo)
          project_tree.project
        else
          project_tree.project.destroy if project_tree.project
          nil
        end
      end

      private

      def restore_version
        Gitlab::ImportExport::VersionRestorer.restore(shared: @shared)
      end

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

      def restore_uploads
        Gitlab::ImportExport::UploadsRestorer.restore(project: project_tree.project, shared: @shared)
      end

      def path_with_namespace(project_path)
        File.join(@namespace.path, project_path)
      end

      def repo_path
        File.join(@shared.export_path, 'project.bundle')
      end

      def wiki_repo_path
        File.join(@shared.export_path, 'project.wiki.bundle')
      end

      def attributes_for_todo
        { user_id: @current_user.id,
          project_id: project_tree.project.id,
          target_type: 'Project',
          target: project_tree.project,
          action: Todo::IMPORTED,
          author_id: @current_user.id,
          state: :pending,
          target_id: project_tree.project.id
        }
      end
    end
  end
end
