# frozen_string_literal: true

module Gitlab
  module Ci
    module Artifacts
      class DecompressedArtifactSizeValidator
        DEFAULT_MAX_BYTES = 4.gigabytes.freeze

        FILE_FORMAT_VALIDATORS = {
          gzip: ::Gitlab::Ci::DecompressedGzipSizeValidator
        }.freeze

        FileDecompressionError = Class.new(::Ci::JobArtifact::InvalidArtifactError)

        # local_archive_path points to an already-downloaded local copy of a
        # remote file, so validation can run on it directly instead of
        # downloading the file again.
        def initialize(file:, file_format:, max_bytes: DEFAULT_MAX_BYTES, local_archive_path: nil)
          @file_path = local_archive_path || file&.path
          @file_format = file_format
          @max_bytes = max_bytes
        end

        def validate!
          validator_class = FILE_FORMAT_VALIDATORS[file_format.to_sym]

          return if file_path.nil?
          return if validator_class.nil?
          return if validator_class.new(archive_path: file_path, max_bytes: max_bytes).valid?

          raise(FileDecompressionError, 'File decompression error')
        end

        private

        attr_reader :file_path, :file_format, :max_bytes
      end
    end
  end
end
