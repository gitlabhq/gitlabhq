# frozen_string_literal: true

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
          project
        else
          raise Projects::ImportService::Error, shared.errors.to_sentence
        end
      rescue StandardError => e
        # If some exception was raised could mean that the SnippetsRepoRestorer
        # was not called. This would leave us with snippets without a repository.
        # This is a state we don't want them to be, so we better delete them.
        remove_non_migrated_snippets

        raise Projects::ImportService::Error, e.message
      ensure
        remove_base_tmp_dir
        remove_import_file
      end

      private

      attr_accessor :archive_file, :current_user, :project, :shared

      def restorers
        [repo_restorer, wiki_restorer, project_tree, avatar_restorer, design_repo_restorer,
         uploads_restorer, lfs_restorer, statistics_restorer, snippets_repo_restorer]
      end

      def import_file
        Gitlab::ImportExport::FileImporter.import(importable: project,
                                                  archive_file: archive_file,
                                                  shared: shared)
      end

      def check_version!
        Gitlab::ImportExport::VersionChecker.check!(shared: shared)
      end

      def project_tree
        @project_tree ||= project_tree_class.new(user: current_user,
                                                 shared: shared,
                                                 project: project)
      end

      def project_tree_class
        sample_data_template? ? Gitlab::ImportExport::Project::Sample::TreeRestorer : Gitlab::ImportExport::Project::TreeRestorer
      end

      def sample_data_template?
        project&.import_data&.data&.dig('sample_data')
      end

      def avatar_restorer
        Gitlab::ImportExport::AvatarRestorer.new(project: project, shared: shared)
      end

      def repo_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: repo_path,
                                               shared: shared,
                                               importable: project)
      end

      def wiki_restorer
        Gitlab::ImportExport::RepoRestorer.new(path_to_bundle: wiki_repo_path,
                                               shared: shared,
                                               importable: ProjectWiki.new(project))
      end

      def design_repo_restorer
        Gitlab::ImportExport::DesignRepoRestorer.new(path_to_bundle: design_repo_path,
                                                     shared: shared,
                                                     importable: project)
      end

      def uploads_restorer
        Gitlab::ImportExport::UploadsRestorer.new(project: project, shared: shared)
      end

      def lfs_restorer
        Gitlab::ImportExport::LfsRestorer.new(project: project, shared: shared)
      end

      def snippets_repo_restorer
        Gitlab::ImportExport::SnippetsRepoRestorer.new(project: project,
                                                       shared: shared,
                                                       user: current_user)
      end

      def statistics_restorer
        Gitlab::ImportExport::StatisticsRestorer.new(project: project, shared: shared)
      end

      def path_with_namespace
        File.join(project.namespace.full_path, project.path)
      end

      def repo_path
        File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename)
      end

      def wiki_repo_path
        File.join(shared.export_path, Gitlab::ImportExport.wiki_repo_bundle_filename)
      end

      def design_repo_path
        File.join(shared.export_path, Gitlab::ImportExport.design_repo_bundle_filename)
      end

      def remove_import_file
        upload = project.import_export_upload

        return unless upload&.import_file&.file

        upload.remove_import_file!
        upload.save!
      end

      def overwrite_project
        return true unless overwrite_project?

        unless can?(current_user, :admin_namespace, project.namespace)
          message = "User #{current_user&.username} (#{current_user&.id}) cannot overwrite a project in #{project.namespace.path}"
          @shared.error(::Projects::ImportService::PermissionError.new(message))
          return false
        end

        ::Projects::OverwriteProjectService.new(project, current_user)
                                            .execute(project_to_overwrite)

        true
      end

      def original_path
        project.import_data&.data&.fetch('original_path', nil)
      end

      def overwrite_project?
        original_path.present? && project_to_overwrite.present?
      end

      def project_to_overwrite
        strong_memoize(:project_to_overwrite) do
          ::Project.find_by_full_path("#{project.namespace.full_path}/#{original_path}")
        end
      end

      def remove_base_tmp_dir
        FileUtils.rm_rf(@shared.base_path)
      end

      def remove_non_migrated_snippets
        project
          .snippets
          .left_joins(:snippet_repository)
          .where(snippet_repositories: { snippet_id: nil })
          .delete_all
      end
    end
  end
end
