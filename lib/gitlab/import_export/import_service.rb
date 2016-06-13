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
        if check_version! && [project_tree, repo_restorer, wiki_restorer, uploads_restorer].all?(&:restore)
          project_tree.project
        else
          project_tree.project.destroy if project_tree.project
          nil
        end
      end

      private

      def check_version!
        Gitlab::ImportExport::VersionChecker.check!(shared: @shared)
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(user: @current_user,
                                                                        shared: @shared,
                                                                        namespace_id: @namespace.id)
      end

      def repo_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                               shared: @shared,
                                               project: project_tree.project)
      end

      def wiki_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: wiki_repo_path,
                                               shared: @shared,
                                               project: ProjectWiki.new(project_tree.project),
                                               wiki: true)
      end

      def uploads_restorer
        Gitlab::ImportExport::UploadsRestorer.new(project: project_tree.project, shared: @shared)
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
