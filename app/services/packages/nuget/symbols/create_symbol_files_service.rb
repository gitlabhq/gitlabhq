# frozen_string_literal: true

module Packages
  module Nuget
    module Symbols
      class CreateSymbolFilesService
        ExtractionError = Class.new(StandardError)
        SYMBOL_ENTRIES_LIMIT = 100
        CONTENT_TYPE = 'application/octet-stream'

        def initialize(package, package_zip_file)
          @package = package
          @symbol_entries = package_zip_file.glob('**/*.pdb')
        end

        def execute
          return if symbol_entries.empty?

          process_symbol_entries
        rescue ExtractionError => e
          Gitlab::ErrorTracking.track_exception(e, class: self.class.name, package_id: package.id)
        end

        private

        attr_reader :package, :symbol_entries

        def process_symbol_entries
          Tempfile.create('nuget_extraction_symbol_file') do |tmp_file|
            symbol_entries.each_with_index do |entry, index|
              raise ExtractionError, 'too many symbol entries' if index >= SYMBOL_ENTRIES_LIMIT

              entry.extract(tmp_file.path) { true }
              File.open(tmp_file.path, 'rb') do |file|
                create_symbol(entry.name, file)
              end
            end
          end
        rescue Zip::EntrySizeError => e
          raise ExtractionError, "symbol file has the wrong entry size: #{e.message}"
        rescue Zip::EntryNameError => e
          raise ExtractionError, "symbol file has the wrong entry name: #{e.message}"
        end

        def create_symbol(path, file)
          signature, checksum = extract_signature_and_checksum(file)
          return if signature.blank? || checksum.blank?

          package.nuget_symbols.create(
            file: { tempfile: file, filename: path.downcase, content_type: CONTENT_TYPE },
            file_path: path,
            signature: signature,
            size: file.size,
            file_sha256: checksum,
            project_id: package.project_id
          )
        rescue StandardError => e
          Gitlab::ErrorTracking.track_exception(e, class: self.class.name, package_id: package.id)
        end

        def extract_signature_and_checksum(file)
          ::Packages::Nuget::Symbols::ExtractSignatureAndChecksumService
            .new(file)
            .execute
            .payload
            .values_at(:signature, :checksum)
        end
      end
    end
  end
end
