# frozen_string_literal: true

module Packages
  module Debian
    class ExtractMetadataService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        extract_metadata
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file &&
          package_file.package&.debian? &&
          package_file.file.size > 0 # rubocop:disable Style/ZeroLengthPredicate
      end

      def file_type_basic
        %i[dsc deb udeb buildinfo changes].each do |format|
          return format if package_file.file_name.end_with?(".#{format}")
        end

        nil
      end

      def file_type_source
        # https://manpages.debian.org/buster/dpkg-dev/dpkg-source.1.en.html
        %i[gzip bzip2 lzma xz].each do |format|
          return :source if package_file.file_name.end_with?(".tar.#{format}")
        end

        nil
      end

      def file_type
        strong_memoize(:file_type) do
          file_type_basic || file_type_source || :unknown
        end
      end

      def file_type_debian?
        file_type == :deb || file_type == :udeb
      end

      def file_type_meta?
        file_type == :dsc || file_type == :buildinfo || file_type == :changes
      end

      def fields
        strong_memoize(:fields) do
          if file_type_debian?
            package_file.file.use_file do |file_path|
              ::Packages::Debian::ExtractDebMetadataService.new(file_path).execute
            end
          elsif file_type_meta?
            package_file.file.use_file do |file_path|
              ::Packages::Debian::ParseDebian822Service.new(File.read(file_path)).execute.each_value.first
            end
          end
        end
      end

      def extract_metadata
        architecture = fields['Architecture'] if file_type_debian?

        {
          file_type: file_type,
          architecture: architecture,
          fields: fields
        }
      end
    end
  end
end
