module Gitlab
  module ImportExport
    class WikiRepoBundler < RepoBundler
      def bundle
        @wiki = ProjectWiki.new(@project)
        return true if !wiki? # it's okay to have no Wiki
        @full_path = File.join(@shared.export_path, project_filename)
        bundle_to_disk
      end

      def bundle_to_disk
        FileUtils.mkdir_p(@shared.export_path)
        git_bundle(repo_path: path_to_repo, bundle_path: @full_path)
      rescue => e
        @shared.error(e.message)
        false
      end

      private

      def project_filename
        "project.wiki.bundle"
      end

      def path_to_repo
        @wiki.repository.path_to_repo
      end

      def wiki?
        File.exists?(@wiki.repository.path_to_repo) && !@wiki.repository.empty?
      end
    end
  end
end
