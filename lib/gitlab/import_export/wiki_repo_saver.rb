module Gitlab
  module ImportExport
    class WikiRepoSaver < RepoSaver
      def save
        @wiki = ProjectWiki.new(@project)
        return true unless wiki_repository_exists? # it's okay to have no Wiki

        bundle_to_disk(File.join(@shared.export_path, project_filename))
      end

      def bundle_to_disk(full_path)
        mkdir_p(@shared.export_path)
        @wiki.repository.bundle_to_disk(full_path)
      rescue => e
        @shared.error(e)
        false
      end

      private

      def project_filename
        "project.wiki.bundle"
      end

      def path_to_repo
        @wiki.repository.path_to_repo
      end

      def wiki_repository_exists?
        File.exist?(@wiki.repository.path_to_repo) && !@wiki.repository.empty?
      end
    end
  end
end
