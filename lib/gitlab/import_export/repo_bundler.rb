module Gitlab
  module ImportExport
    class RepoBundler
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project: , shared: )
        @project = project
        @export_path = shared.export_path
      end

      def bundle
        return false if @project.empty_repo?
        @full_path = File.join(@export_path, project_filename)
        bundle_to_disk
      end

      private

      def bundle_to_disk
        FileUtils.mkdir_p(@export_path)
        git_bundle(repo_path: path_to_repo, bundle_path: @full_path)
      rescue
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
