# frozen_string_literal: true

module Packages
  module Debian
    class ExtractChangesMetadataService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
        @entries = {}
      end

      def execute
        {
          file_type: file_type,
          architecture: metadata[:architecture],
          fields: fields,
          files: files
        }
      rescue ActiveModel::ValidationError => e
        raise ExtractionError, e.message
      end

      private

      def metadata
        strong_memoize(:metadata) do
          ::Packages::Debian::ExtractMetadataService.new(@package_file).execute
        end
      end

      def file_type
        metadata[:file_type]
      end

      def fields
        metadata[:fields]
      end

      def files
        strong_memoize(:files) do
          raise ExtractionError, "is not a changes file" unless file_type == :changes
          raise ExtractionError, "Files field is missing" if fields['Files'].blank?
          raise ExtractionError, "Checksums-Sha1 field is missing" if fields['Checksums-Sha1'].blank?
          raise ExtractionError, "Checksums-Sha256 field is missing" if fields['Checksums-Sha256'].blank?

          init_entries_from_files
          entries_from_checksums_sha1
          entries_from_checksums_sha256
          entries_from_package_files

          @entries
        end
      end

      def init_entries_from_files
        each_lines_for('Files') do |line|
          md5sum, size, section, priority, filename = line.split
          entry = FileEntry.new(
            filename: filename,
            size: size.to_i,
            md5sum: md5sum,
            section: section,
            priority: priority)

          @entries[filename] = entry
        end
      end

      def entries_from_checksums_sha1
        each_lines_for('Checksums-Sha1') do |line|
          sha1sum, size, filename = line.split
          entry = @entries[filename]
          raise ExtractionError, "#{filename} is listed in Checksums-Sha1 but not in Files" unless entry
          raise ExtractionError, "Size for #{filename} in Files and Checksums-Sha1 differ" unless entry.size == size.to_i

          entry.sha1sum = sha1sum
        end
      end

      def entries_from_checksums_sha256
        each_lines_for('Checksums-Sha256') do |line|
          sha256sum, size, filename = line.split
          entry = @entries[filename]
          raise ExtractionError, "#{filename} is listed in Checksums-Sha256 but not in Files" unless entry
          raise ExtractionError, "Size for #{filename} in Files and Checksums-Sha256 differ" unless entry.size == size.to_i

          entry.sha256sum = sha256sum
        end
      end

      def each_lines_for(field)
        fields[field].split("\n").each do |line|
          next if line.blank?

          yield(line)
        end
      end

      def entries_from_package_files
        @entries.each do |filename, entry|
          entry.package_file = ::Packages::PackageFileFinder.new(@package_file.package, filename).execute!
          entry.validate!
        rescue ActiveRecord::RecordNotFound
          raise ExtractionError, "#{filename} is listed in Files but was not uploaded"
        end
      end
    end
  end
end
