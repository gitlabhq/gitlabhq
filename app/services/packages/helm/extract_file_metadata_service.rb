# frozen_string_literal: true

require 'rubygems/package'

module Packages
  module Helm
    class ExtractFileMetadataService
      ExtractionError = Class.new(StandardError)

      # Charts must be smaller than 1M because of the storage limitations of Kubernetes objects.
      # based on https://helm.sh/docs/chart_template_guide/accessing_files/
      MAX_FILE_SIZE = 1.megabytes.freeze

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        metadata
      end

      private

      def valid_package_file?
        @package_file && @package_file.package&.helm? && !@package_file.file.empty_size?
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
          raise ExtractionError, 'Chart.yaml too big' if chart_yaml.size > MAX_FILE_SIZE

          chart_yaml.read
        ensure
          tar_reader.close
        end
      end
    end
  end
end
