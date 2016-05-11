module Gitlab
  module ImportExport
    class Saver
      include Gitlab::ImportExport::CommandLineUtil

      def self.save(*args)
        new(*args).save
      end

      def initialize(shared:)
        @shared = shared
      end

      def save
        if compress_and_save
          remove_storage_path
          Rails.logger.info("Saved project export #{archive_file}")
          archive_file
        else
          false
        end
      rescue => e
        @shared.error(e.message)
        false
      end

      private

      def compress_and_save
        tar_czf(archive: archive_file, dir: @shared.storage_path)
      end

      def remove_storage_path
        FileUtils.rm_rf(@shared.storage_path)
      end

      def archive_file
        @archive_file ||= File.join(@shared.storage_path, '..', "#{Time.now.strftime('%Y-%m-%d_%H-%M-%3N')}_project_export.tar.gz")
      end
    end
  end
end
