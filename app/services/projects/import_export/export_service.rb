module Projects
  module ImportExport
    class ExportService < BaseService

      def execute(options = {})
        @shared = Gitlab::ImportExport::Shared.new(relative_path: File.join(project.path_with_namespace, 'work'))
        # TODO handle errors
        save_all if [save_project_tree, bundle_repo, bundle_wiki_repo].all?
      end

      private

      def save_project_tree
        Gitlab::ImportExport::ProjectTreeSaver.new(project: project, shared: @shared).save
      end

      def bundle_repo
        Gitlab::ImportExport::RepoBundler.new(project: project, shared: @shared).bundle
      end

      def bundle_wiki_repo
        Gitlab::ImportExport::WikiRepoBundler.new(project: project, shared: @shared).bundle
      end

      def save_all
        Gitlab::ImportExport::Saver.save(storage_path: @shared.export_path)
      end
    end
  end
end
