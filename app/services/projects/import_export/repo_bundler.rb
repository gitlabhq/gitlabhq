module Projects
  module ImportExport
    class RepoBundler
      include Projects::ImportExport::CommandLineUtil

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
        tar_cf(archive: full_path, dir: path_to_repo)
      rescue
        #TODO: handle error
        false
      end

      def project_filename
        "#{@project.namespace}#{@project.name}.bundle"
      end

      def path_to_repo
        @project.repository.path_to_repo
      end
    end
  end
end
