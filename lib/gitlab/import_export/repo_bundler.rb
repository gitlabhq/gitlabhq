module Gitlab
  module ImportExport
    class RepoBundler
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project: , shared: )
        @project = project
        @shared = shared
      end

      def bundle
        return false if @project.empty_repo?
        @full_path = File.join(@shared.export_path, project_filename)
        bundle_to_disk
      end

      private

      def bundle_to_disk
        FileUtils.mkdir_p(@shared.export_path)
        git_bundle(repo_path: path_to_repo, bundle_path: @full_path)
      rescue => e
        @shared.error(e.message)
        false
      end

      # TODO remove magic keyword and move it to a shared config
      def project_filename
        "project.bundle"
      end

      def path_to_repo
        @project.repository.path_to_repo
      end
    end
  end
end
