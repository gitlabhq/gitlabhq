module Gitlab
  module ImportExport
    class UploadsSaver
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        return true unless File.directory?(uploads_path)

        copy_files(uploads_path, uploads_export_path)
      rescue => e
        @shared.error(e)
        false
      end

      private

      def uploads_export_path
        File.join(@shared.export_path, 'uploads')
      end

      def uploads_path
        # TODO: decide what to do with uploads. We will use UUIDs here too?
        File.join(Rails.root.join('public/uploads'), @project.path_with_namespace)
      end
    end
  end
end
