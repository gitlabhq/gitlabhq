# frozen_string_literal: true

require 'rubygems/package'

module Packages
  module Helm
    class ExtractFileMetadataService
      ExtractionError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        metadata
      end

      private

      def valid_package_file?
        @package_file &&
          @package_file.package&.helm? &&
          @package_file.file.size > 0 # rubocop:disable Style/ZeroLengthPredicate
      end

      def metadata
        YAML.safe_load(chart_yaml_content)
      rescue Psych::Exception => e
        raise ExtractionError, "Error while parsing Chart.yaml: #{e.message}"
      end

      def chart_yaml_content
        @package_file.file.use_open_file do |file|
          tar_reader = Gem::Package::TarReader.new(Zlib::GzipReader.new(file))

          chart_yaml = tar_reader.find do |entry|
            next unless entry.file?

            entry.full_name.end_with?('/Chart.yaml')
          end

          raise ExtractionError, 'Chart.yaml not found within a directory' unless chart_yaml

          chart_yaml.read
        ensure
          tar_reader.close
        end
      end
    end
  end
end
