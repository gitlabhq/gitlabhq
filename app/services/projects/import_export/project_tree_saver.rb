module Projects
  module ImportExport
    class ProjectTreeSaver
      attr_reader :full_path

      def initialize(project: , shared: )
        @project = project
        @export_path = shared.export_path
      end

      def save
        @full_path = File.join(@export_path, project_filename)
        save_to_disk
      end

      private

      def save_to_disk
        FileUtils.mkdir_p(@export_path)
        File.write(full_path, project_json_tree)
        true
      rescue
        #TODO: handle error
        false
      end

      def project_filename
        # TODO sanitize name
        "#{@project.name}.json"
      end

      def project_json_tree
        @project.to_json(Projects::ImportExport.project_tree)
      end
    end
  end
end
