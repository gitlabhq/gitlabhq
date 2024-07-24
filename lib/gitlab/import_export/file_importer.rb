# frozen_string_literal: true

module Gitlab
  module ImportExport
    class FileImporter
      include Gitlab::ImportExport::CommandLineUtil

      ImporterError = Class.new(StandardError)

      MAX_RETRIES = 8

      def self.import(*args, **kwargs)
        new(*args, **kwargs).import
      end

      def initialize(importable:, archive_file:, shared:, user:, tmpdir: nil)
        @importable = importable
        @archive_file = archive_file
        @shared = shared
        @user = user
        @tmpdir = tmpdir
      end

      def import
        prepare_extraction_dir

        copy_archive

        wait_for_archived_file do
          validate_decompressed_archive_size
          decompress_archive
        end
      rescue StandardError => e
        @shared.error(e)
        false
      ensure
        remove_import_file
        clean_extraction_dir!(target_directory) if should_clean_extraction_dir?
      end

      private

      def prepare_extraction_dir
        if @tmpdir
          @tmpdir_valid = validate_tmpdir!
        else
          mkdir_p(@shared.export_path)
          mkdir_p(@shared.archive_path)
        end

        clean_extraction_dir!(target_directory)
      end

      # Exponentially sleep until I/O finishes copying the file
      def wait_for_archived_file
        MAX_RETRIES.times do |retry_number|
          break if File.exist?(@archive_file)

          sleep(2**retry_number)
        end

        yield
      end

      def decompress_archive
        result = untar_zxf(archive: @archive_file, dir: target_directory)

        raise ImporterError, "Unable to decompress #{@archive_file} into #{target_directory}" unless result

        result
      end

      def copy_archive
        return if @archive_file

        @archive_file = File.join(source_directory, Gitlab::ImportExport.export_filename(exportable: @importable))

        remote_download_or_download_or_copy_upload
      end

      def source_directory
        return @tmpdir if @tmpdir

        @shared.archive_path
      end

      def target_directory
        return @tmpdir if @tmpdir

        @shared.export_path
      end

      def remote_download_or_download_or_copy_upload
        import_export_upload = @importable.import_export_upload_by_user(@user)

        if import_export_upload.remote_import_url.present?
          download(
            import_export_upload.remote_import_url,
            @archive_file,
            size_limit: file_size_limit
          )
        else
          download_or_copy_upload(
            import_export_upload.import_file,
            @archive_file,
            size_limit: file_size_limit
          )
        end
      end

      def file_size_limit
        Gitlab::CurrentSettings.current_application_settings.max_import_remote_file_size.megabytes
      end

      def remove_import_file
        FileUtils.rm_rf(@archive_file) if @archive_file
      end

      def validate_decompressed_archive_size
        raise ImporterError, _('Decompressed archive size validation failed.') unless size_validator.valid?
      end

      def size_validator
        @size_validator ||= DecompressedArchiveSizeValidator.new(archive_path: @archive_file)
      end

      def validate_tmpdir!
        Gitlab::PathTraversal.check_path_traversal!(@tmpdir)
        Gitlab::PathTraversal.check_allowed_absolute_path!(@tmpdir, [Dir.tmpdir])

        true
      end

      attr_reader :tmpdir_valid

      def should_clean_extraction_dir?
        return true if @tmpdir.nil?

        tmpdir_valid
      end
    end
  end
end
