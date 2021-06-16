# frozen_string_literal: true

module BulkImports
  class FileDecompressionService
    include Gitlab::ImportExport::CommandLineUtil

    ServiceError = Class.new(StandardError)

    def initialize(dir:, filename:)
      @dir = dir
      @filename = filename
      @filepath = File.join(@dir, @filename)
      @decompressed_filename = File.basename(@filename, '.gz')
      @decompressed_filepath = File.join(@dir, @decompressed_filename)
    end

    def execute
      validate_dir
      validate_decompressed_file_size if Feature.enabled?(:validate_import_decompressed_archive_size, default_enabled: :yaml)
      validate_symlink(filepath)

      decompress_file

      validate_symlink(decompressed_filepath)

      filepath
    rescue StandardError => e
      File.delete(filepath) if File.exist?(filepath)
      File.delete(decompressed_filepath) if File.exist?(decompressed_filepath)

      raise e
    end

    private

    attr_reader :dir, :filename, :filepath, :decompressed_filename, :decompressed_filepath

    def validate_dir
      raise(ServiceError, 'Invalid target directory') unless dir.start_with?(Dir.tmpdir)
    end

    def validate_decompressed_file_size
      raise(ServiceError, 'File decompression error') unless size_validator.valid?
    end

    def validate_symlink(filepath)
      raise(ServiceError, 'Invalid file') if File.lstat(filepath).symlink?
    end

    def decompress_file
      gunzip(dir: dir, filename: filename)
    end

    def size_validator
      @size_validator ||= Gitlab::ImportExport::DecompressedArchiveSizeValidator.new(archive_path: filepath)
    end
  end
end
