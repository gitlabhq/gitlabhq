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

        if file_type == :unsupported
          raise ExtractionError, "unsupported file extension for file #{package_file.file_name}"
        end

        extract_metadata
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file && package_file.package&.debian? && !package_file.file.empty_size?
      end

      def file_type_basic
        %i[dsc deb udeb buildinfo changes ddeb].each do |format|
          return format if package_file.file_name.end_with?(".#{format}")
        end

        nil
      end

      def file_type_source
        # https://manpages.debian.org/buster/dpkg-dev/dpkg-source.1.en.html#Format:_3.0_(quilt)
        %i[gz bz2 lzma xz].each do |format|
          return :source if package_file.file_name.end_with?(".tar.#{format}")
        end

        nil
      end

      def file_type
        file_type_basic || file_type_source || :unsupported
      end
      strong_memoize_attr :file_type

      def file_type_debian?
        file_type == :deb || file_type == :udeb || file_type == :ddeb
      end

      def file_type_meta?
        file_type == :dsc || file_type == :buildinfo || file_type == :changes
      end

      def fields
        if file_type_debian?
          package_file.file.use_open_file(unlink_early: false) do |file|
            ::Packages::Debian::ExtractDebMetadataService.new(file.file_path).execute
          end
        elsif file_type_meta?
          package_file.file.use_open_file do |file|
            ::Packages::Debian::ParseDebian822Service.new(file.read).execute.each_value.first
          end
        end
      end
      strong_memoize_attr :fields

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
