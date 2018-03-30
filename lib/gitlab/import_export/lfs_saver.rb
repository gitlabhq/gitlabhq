module Gitlab
  module ImportExport
    class LfsSaver
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        return true if @project.lfs_objects.empty?

        @project.lfs_objects.each do |lfs_object|
          save_lfs_object(lfs_object)
        end

        true
      rescue => e
        @shared.error(e)

        false
      end

      private

      def save_lfs_object(lfs_object)
        if lfs_object.local_store?
          copy_file_for_lfs_object(lfs_object)
        else
          raise NotImplementedError.new "Exporting files from object storage is not yet supported"
        end
      end

      def copy_file_for_lfs_object(lfs_object)
        copy_files(lfs_object.file.path, destination_path_for_object(lfs_object))
      end

      def destination_path_for_object(lfs_object)
        File.join(lfs_export_path, lfs_object.oid)
      end

      def lfs_export_path
        File.join(@shared.export_path, 'lfs-objects')
      end
    end
  end
end
