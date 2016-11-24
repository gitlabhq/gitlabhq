module Gitlab
  module ImportExport
    class ProjectTreeSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project:, shared:)
        @project = project
        @shared = shared
        @full_path = File.join(@shared.export_path, ImportExport.project_filename)
      end

      def save
        mkdir_p(@shared.export_path)

        File.write(full_path, project_json_tree)
        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def project_json_tree
        @project.to_json(Gitlab::ImportExport::Reader.new(shared: @shared).project_tree)
      end
    end
  end
end
