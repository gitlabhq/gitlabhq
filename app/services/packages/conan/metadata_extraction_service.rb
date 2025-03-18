# frozen_string_literal: true

module Packages
  module Conan
    class MetadataExtractionService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      SECTION_HEADER_REGEX = /^\[(\w{1,50})\]$/
      RECIPE_HASH_SECTION = 'recipe_hash'
      ALLOWED_SECTIONS = %w[requires recipe_hash options settings].freeze

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        result = parse_conaninfo_content

        package_reference.update!(info: result)
        ServiceResponse.success
      rescue ActiveRecord::RecordInvalid => e
        error_message = e.record.errors.full_messages.first
        raise ExtractionError, "conaninfo.txt file too large" if error_message.include?("Info conaninfo is too large")

        raise ExtractionError, "conaninfo.txt metadata failedto be saved: #{error_message}"
      end

      private

      attr_reader :package_file

      def parse_conaninfo_content
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          parse_file_contents(File.open(open_file.file_path))
        end
      rescue StandardError => e
        raise ExtractionError, "Error while parsing conaninfo.txt: #{e.message}"
      end

      def parse_file_contents(file)
        result = {}
        current_section = current_data = nil

        file.each do |line|
          line = line.strip
          next if line.empty?

          section_name = section_name_from(line)
          if section_name
            if current_section && current_data && allowed_section?(current_section)
              result[current_section] = current_data
            end

            current_section = section_name
            current_data = nil
          elsif current_section && allowed_section?(current_section)
            validate_recipe_hash_section(current_section, current_data)
            current_data = process_section_line(current_section, line, current_data)
          end
        end

        result[current_section] = current_data if current_section && current_data && allowed_section?(current_section)
        result
      end

      def validate_recipe_hash_section(section, data)
        return unless section == RECIPE_HASH_SECTION && data

        raise ExtractionError, 'The recipe_hash section cannot have multiple lines'
      end

      def process_section_line(section, line, data)
        return line if section == RECIPE_HASH_SECTION
        return process_key_value_line(line, data) if line.include?('=')

        process_array_line(line, data)
      end

      def process_key_value_line(line, data)
        data ||= {}
        key, value = line.split('=', 2).map(&:strip)
        raise ExtractionError, "Invalid key-value line: #{line}" if key.empty? || value.empty?

        data[key] = value
        data
      end

      def process_array_line(line, data)
        data ||= []
        data << line
      end

      def allowed_section?(section)
        strong_memoize_with(:allowed_section, section) do
          ALLOWED_SECTIONS.include?(section)
        end
      end

      def section_name_from(line)
        section = line.match(SECTION_HEADER_REGEX)&.captures&.first
        raise ExtractionError, "Invalid section header: #{line}" if section.nil? && line.start_with?('[')

        section
      end

      def package_reference
        package_file.conan_file_metadatum.package_reference
      end
    end
  end
end
