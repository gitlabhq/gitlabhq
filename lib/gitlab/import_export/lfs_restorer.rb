module Gitlab
  module ImportExport
    class LfsRestorer
      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        return true if lfs_file_paths.empty?

        lfs_file_paths.each do |file_path|
          link_or_create_lfs_object!(file_path)
        end

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def link_or_create_lfs_object!(path)
        size = File.size(path)
        oid = LfsObject.calculate_oid(path)

        lfs_object = LfsObject.find_or_initialize_by(oid: oid, size: size)
        lfs_object.file = File.open(path) unless lfs_object.file&.exists?

        @project.all_lfs_objects << lfs_object
      end

      def lfs_file_paths
        @lfs_file_paths ||= Dir.glob("#{lfs_storage_path}/*")
      end

      def lfs_storage_path
        File.join(@shared.export_path, 'lfs-objects')
      end
    end
  end
end
