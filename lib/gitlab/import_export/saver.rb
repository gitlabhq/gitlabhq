module Gitlab
  module ImportExport
    class Saver
      include Gitlab::ImportExport::CommandLineUtil

      def self.save(*args)
        new(*args).save
      end

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        if compress_and_save
          remove_export_path
          Rails.logger.info("Saved project export #{archive_file}")
          archive_file
        else
          @shared.error(Gitlab::ImportExport::Error.new("Unable to save #{archive_file} into #{@shared.export_path}"))
          false
        end
      rescue => e
        @shared.error(e)
        false
      end

      private

      def compress_and_save
        tar_czf(archive: archive_file, dir: @shared.export_path)
      end

      def remove_export_path
        FileUtils.rm_rf(@shared.export_path)
      end

      def archive_file
        @archive_file ||= File.join(@shared.archive_path, Gitlab::ImportExport.export_filename(project: @project))
      end
    end
  end
end
