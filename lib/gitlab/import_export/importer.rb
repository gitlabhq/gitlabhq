module Gitlab
  module ImportExport
    class Importer
      include Gitlab::Allowable
      include Gitlab::Utils::StrongMemoize

      def self.imports_repository?
        true
      end

      def initialize(project)
        @archive_file = project.import_source
        @current_user = project.creator
        @project = project
        @shared = project.import_export_shared
      end

      def execute
        if import_file && check_version! && restorers.all?(&:restore) && overwrite_project
          project_tree.restored_project
        else
          raise Projects::ImportService::Error.new(@shared.errors.join(', '))
        end
      rescue => e
        raise Projects::ImportService::Error.new(e.message)
      ensure
        remove_import_file
      end

      private

      def restorers
        [repo_restorer, wiki_restorer, project_tree, avatar_restorer,
         uploads_restorer, lfs_restorer, statistics_restorer]
      end

      def import_file
        Gitlab::ImportExport::FileImporter.import(archive_file: @archive_file,
                                                  shared: @shared)
      end

      def check_version!
        Gitlab::ImportExport::VersionChecker.check!(shared: @shared)
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(user: @current_user,
                                                                        shared: @shared,
                                                                        project: @project)
      end

      def avatar_restorer
        Gitlab::ImportExport::AvatarRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def repo_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                               shared: @shared,
                                               project: project_tree.restored_project)
      end

      def wiki_restorer
        Gitlab::ImportExport::WikiRestorer.new(path_to_bundle: wiki_repo_path,
                                               shared: @shared,
                                               project: ProjectWiki.new(project_tree.restored_project),
                                               wiki_enabled: @project.wiki_enabled?)
      end

      def uploads_restorer
        Gitlab::ImportExport::UploadsRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def lfs_restorer
        Gitlab::ImportExport::LfsRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def statistics_restorer
        Gitlab::ImportExport::StatisticsRestorer.new(project: project_tree.restored_project, shared: @shared)
      end

      def path_with_namespace
        File.join(@project.namespace.full_path, @project.path)
      end

      def repo_path
        File.join(@shared.export_path, 'project.bundle')
      end

      def wiki_repo_path
        File.join(@shared.export_path, 'project.wiki.bundle')
      end

      def remove_import_file
        FileUtils.rm_rf(@archive_file)
      end

      def overwrite_project
        project = project_tree.restored_project

        return unless can?(@current_user, :admin_namespace, project.namespace)

        if overwrite_project?
          ::Projects::OverwriteProjectService.new(project, @current_user)
                                             .execute(project_to_overwrite)
        end

        true
      end

      def original_path
        @project.import_data&.data&.fetch('original_path', nil)
      end

      def overwrite_project?
        original_path.present? && project_to_overwrite.present?
      end

      def project_to_overwrite
        strong_memoize(:project_to_overwrite) do
          Project.find_by_full_path("#{@project.namespace.full_path}/#{original_path}")
        end
      end
    end
  end
end
