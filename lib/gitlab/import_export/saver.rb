# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Saver
      include Gitlab::ImportExport::CommandLineUtil

      def self.save(*args, **kwargs)
        new(*args, **kwargs).save
      end

      def initialize(exportable:, shared:)
        @exportable = exportable
        @shared = shared
      end

      def save
        if compress_and_save
          Gitlab::Export::Logger.info(
            message: 'Export archive saved',
            exportable_class: @exportable.class.to_s,
            archive_file: archive_file
          )

          save_upload
        else
          @shared.error(Gitlab::ImportExport::Error.new(error_message))
          false
        end
      rescue StandardError => e
        @shared.error(e)
        false
      ensure
        remove_archive_tmp_dir
      end

      private

      def compress_and_save
        tar_czf(archive: archive_file, dir: @shared.export_path)
      end

      def remove_archive_tmp_dir
        FileUtils.rm_rf(@shared.archive_path)
      end

      def archive_file
        @archive_file ||= File.join(@shared.archive_path, Gitlab::ImportExport.export_filename(exportable: @exportable))
      end

      def save_upload
        upload = initialize_upload

        File.open(archive_file) { |file| upload.export_file = file }

        upload.save!
      end

      def error_message
        "Unable to save #{archive_file} into #{@shared.export_path}."
      end

      def initialize_upload
        exportable_kind = @exportable.class.name.downcase

        ImportExportUpload.find_or_initialize_by(Hash[exportable_kind, @exportable])
      end
    end
  end
end
