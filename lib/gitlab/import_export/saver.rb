module Gitlab
  module ImportExport
    class Saver
      include Gitlab::ImportExport::CommandLineUtil

      def self.save(*args)
        new(*args).save
      end

      def initialize(storage_path:)
        @storage_path = storage_path
      end

      def save
        if compress_and_save
          remove_storage_path
          archive_file
        else
          false
        end
      end

      private

      def compress_and_save
        tar_czf(archive: archive_file, dir: @storage_path)
      end

      def remove_storage_path
        FileUtils.rm_rf(@storage_path)
      end

      def archive_file
        @archive_file ||= File.join(@storage_path, '..', 'project.tar.gz')
      end
    end
  end
end
