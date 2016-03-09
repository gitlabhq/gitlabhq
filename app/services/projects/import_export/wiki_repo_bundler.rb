module Projects
  module ImportExport
    class WikiRepoBundler < RepoBundler
      def bundle
        @wiki = ProjectWiki.new(@project)
        return false if !wiki?
        @full_path = File.join(@export_path, project_filename)
        bundle_to_disk
      end

      def bundle_to_disk
        FileUtils.mkdir_p(@export_path)
        git_bundle(repo_path: path_to_repo, bundle_path: @full_path)
      rescue
        #TODO: handle error
        false
      end

      private

      def project_filename
        "#{@project.name}.wiki.bundle"
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
