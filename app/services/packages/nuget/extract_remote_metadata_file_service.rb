# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractRemoteMetadataFileService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      MAX_FILE_SIZE = 4.megabytes.freeze
      METADATA_FILE_EXTENSION = '.nuspec'
      MAX_FRAGMENTS = 5 # nuspec file is usually in the first 2 fragments but we buffer 5 max

      def initialize(remote_url)
        @remote_url = remote_url
      end

      def execute
        return ServiceResponse.error(message: 'invalid file url') if remote_url.blank?

        if nuspec_file_content.blank? || !nuspec_file_content.instance_of?(String)
          return ServiceResponse.error(message: 'nuspec file not found', reason: :nuspec_extraction_failed)
        end

        ServiceResponse.success(payload: nuspec_file_content)
      rescue ExtractionError => e
        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :remote_url

      def nuspec_file_content
        fragments = []

        Gitlab::HTTP.get(remote_url, stream_body: true, allow_object_storage: true) do |fragment|
          break if fragments.size >= MAX_FRAGMENTS

          fragments << fragment
          joined_fragments = fragments.join

          next if joined_fragments.exclude?(METADATA_FILE_EXTENSION)

          nuspec_content = extract_nuspec_file(joined_fragments)

          break nuspec_content if nuspec_content.present?
        end
      end
      strong_memoize_attr :nuspec_file_content

      def extract_nuspec_file(fragments)
        StringIO.open(fragments) do |io|
          Zip::InputStream.open(io) do |zip|
            process_zip_entries(zip)
          end
        rescue Zip::Error => e
          raise ExtractionError, "Error opening zip stream: #{e.message}"
        end
      end

      def process_zip_entries(zip)
        while (entry = zip.get_next_entry) # rubocop:disable Lint/AssignmentInCondition
          next unless entry.name.end_with?(METADATA_FILE_EXTENSION)

          raise ExtractionError, 'nuspec file too big' if entry.size > MAX_FILE_SIZE

          return extract_file_content(entry)
        end
      end

      def extract_file_content(entry)
        Tempfile.create('extract_remote_metadata_file_service') do |file|
          entry.extract(file.path) { true } # allow #extract to overwrite the file
          file.read
        end
      rescue Zip::DecompressionError
        '' # Ignore decompression errors and continue reading the next fragment
      rescue Zip::EntrySizeError => e
        raise ExtractionError, "nuspec file has the wrong entry size: #{e.message}"
      end
    end
  end
end
