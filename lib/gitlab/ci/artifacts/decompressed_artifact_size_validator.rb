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

        def initialize(file:, file_format:, max_bytes: DEFAULT_MAX_BYTES)
          @file = file
          @file_path = file&.path
          @file_format = file_format
          @max_bytes = max_bytes
        end

        def validate!
          validator_class = FILE_FORMAT_VALIDATORS[file_format.to_sym]

          return if file_path.nil?
          return if validator_class.nil?

          if file.respond_to?(:object_store) && file.object_store == ObjectStorage::Store::REMOTE
            return if valid_on_storage?(validator_class)
          elsif validator_class.new(archive_path: file_path, max_bytes: max_bytes).valid?
            return
          end

          raise(FileDecompressionError, 'File decompression error')
        end

        private

        attr_reader :file_path, :file, :file_format, :max_bytes

        def valid_on_storage?(validator_class)
          temp_filename = "#{SecureRandom.uuid}.gz"

          is_valid = false
          Tempfile.open(temp_filename, '/tmp') do |tempfile|
            tempfile.binmode
            ::Faraday.get(file.url) do |req|
              req.options.on_data = proc { |chunk, _| tempfile.write(chunk) }
            end

            is_valid = validator_class.new(archive_path: tempfile.path, max_bytes: max_bytes).valid?
            tempfile.unlink
          end

          is_valid
        end
      end
    end
  end
end
