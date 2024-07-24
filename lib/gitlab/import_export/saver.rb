# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Saver
      include Gitlab::ImportExport::CommandLineUtil

      def self.save(*args, **kwargs)
        new(*args, **kwargs).save
      end

      def initialize(exportable:, shared:, user:)
        @exportable = exportable
        @shared = shared
        @user = user
      end

      def save
        if compress_and_save
          log_export_results('Export archive saved')

          save_upload

          log_export_results('Export archive uploaded')
        else
          @shared.error(Gitlab::ImportExport::Error.new(error_message))

          false
        end
      rescue StandardError => e
        @shared.error(e)
        log_export_results('Export archive saver failed')

        false
      ensure
        remove_archive_tmp_dir
      end

      private

      attr_accessor :compress_duration_s, :assign_duration_s, :upload_duration_s, :upload_bytes

      def compress_and_save
        result = nil

        @compress_duration_s = Benchmark.realtime do
          result = tar_czf(archive: archive_file, dir: @shared.export_path)
        end

        result
      end

      def remove_archive_tmp_dir
        FileUtils.rm_rf(@shared.archive_path)
      end

      def archive_file
        @archive_file ||= File.join(@shared.archive_path, Gitlab::ImportExport.export_filename(exportable: @exportable))
      end

      def save_upload
        upload = initialize_upload

        @upload_bytes = File.size(archive_file)
        @assign_duration_s = Benchmark.realtime do
          File.open(archive_file) { |file| upload.export_file = file }
        end

        @upload_duration_s = Benchmark.realtime { upload.save! }

        true
      end

      def error_message
        "Unable to save #{archive_file} into #{@shared.export_path}."
      end

      def initialize_upload
        exportable_kind = @exportable.class.name.downcase

        ImportExportUpload.find_or_initialize_by(Hash[exportable_kind, @exportable].merge(user: @user))
      end

      def log_export_results(message)
        Gitlab::Export::Logger.info(message: message, **log_data)
      end

      def log_data
        ApplicationContext.current.merge(
          {
            exportable_class: @exportable.class.to_s,
            archive_file: archive_file,
            compress_duration_s: compress_duration_s&.round(6),
            assign_duration_s: assign_duration_s&.round(6),
            upload_duration_s: upload_duration_s&.round(6),
            upload_bytes: upload_bytes
          }
        ).compact
      end
    end
  end
end
