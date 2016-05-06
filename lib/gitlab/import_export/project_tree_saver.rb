module Gitlab
  module ImportExport
    class ProjectTreeSaver
      attr_reader :full_path

      def initialize(project:, shared:)
        @project = project
        @export_path = shared.export_path
        @full_path = File.join(@export_path, project_filename)
      end

      def save
        FileUtils.mkdir_p(@export_path)
        File.write(full_path, project_json_tree)
        true
      rescue
        # TODO: handle error
        false
      end

      private

      # TODO remove magic keyword and move it to a shared config
      def project_filename
        "project.json"
      end

      def project_json_tree
        @project.to_json(Gitlab::ImportExport.project_tree)
      end
    end
  end
end
