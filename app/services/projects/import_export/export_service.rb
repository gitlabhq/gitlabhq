module Projects
  module ImportExport
    class ExportService < BaseService

      def execute(_options = {})
        @shared = Gitlab::ImportExport::Shared.new(relative_path: File.join(project.path_with_namespace, 'work'))
        save_all
      end

      private

      def save_all
        if [version_saver, project_tree_saver, uploads_saver, repo_saver, wiki_repo_saver].all?(&:save)
          Gitlab::ImportExport::Saver.save(shared: @shared)
        else
          cleanup_and_notify_worker
        end
      end

      def version_saver
        Gitlab::ImportExport::VersionSaver.new(shared: @shared)
      end

      def project_tree_saver
        Gitlab::ImportExport::ProjectTreeSaver.new(project: project, shared: @shared)
      end

      def uploads_saver
        Gitlab::ImportExport::UploadsSaver.new(project: project, shared: @shared)
      end

      def repo_saver
        Gitlab::ImportExport::RepoSaver.new(project: project, shared: @shared)
      end

      def wiki_repo_saver
        Gitlab::ImportExport::WikiRepoSaver.new(project: project, shared: @shared)
      end

      def cleanup_and_notify_worker
        FileUtils.rm_rf(@shared.export_path)
        raise Gitlab::ImportExport::Error.new(@shared.errors.join(', '))
      end
    end
  end
end
