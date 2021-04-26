# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        class Cobertura
          InvalidXMLError = Class.new(Gitlab::Ci::Parsers::ParserError)
          InvalidLineInformationError = Class.new(Gitlab::Ci::Parsers::ParserError)

          GO_SOURCE_PATTERN = '/usr/local/go/src'
          MAX_SOURCES = 100

          def parse!(xml_data, coverage_report, project_path: nil, worktree_paths: nil)
            root = Hash.from_xml(xml_data)

            context = {
              project_path: project_path,
              paths: worktree_paths&.to_set,
              sources: []
            }

            parse_all(root, coverage_report, context)
          rescue Nokogiri::XML::SyntaxError
            raise InvalidXMLError, "XML parsing failed"
          end

          private

          def parse_all(root, coverage_report, context)
            return unless root.present?

            root.each do |key, value|
              parse_node(key, value, coverage_report, context)
            end
          end

          def parse_node(key, value, coverage_report, context)
            if key == 'sources' && value && value['source'].present?
              parse_sources(value['source'], context)
            elsif key == 'package'
              Array.wrap(value).each do |item|
                parse_package(item, coverage_report, context)
              end
            elsif key == 'class'
              # This means the cobertura XML does not have classes within package nodes.
              # This is possible in some cases like in simple JS project structures
              # running Jest.
              Array.wrap(value).each do |item|
                parse_class(item, coverage_report, context)
              end
            elsif value.is_a?(Hash)
              parse_all(value, coverage_report, context)
            elsif value.is_a?(Array)
              value.each do |item|
                parse_all(item, coverage_report, context)
              end
            end
          end

          def parse_sources(sources, context)
            return unless context[:project_path] && context[:paths]

            sources = Array.wrap(sources)

            # TODO: Go cobertura has a different format with how their packages
            # are included in the filename. So we can't rely on the sources.
            # We'll deal with this later.
            return if sources.include?(GO_SOURCE_PATTERN)

            sources.each do |source|
              source = build_source_path(source, context)
              context[:sources] << source if source.present?
            end
          end

          def build_source_path(source, context)
            # | raw source                  | extracted  |
            # |-----------------------------|------------|
            # | /builds/foo/test/SampleLib/ | SampleLib/ |
            # | /builds/foo/test/something  | something  |
            # | /builds/foo/test/           | nil        |
            # | /builds/foo/test            | nil        |
            source.split("#{context[:project_path]}/", 2)[1]
          end

          def parse_package(package, coverage_report, context)
            classes = package.dig('classes', 'class')
            return unless classes.present?

            matched_filenames = Array.wrap(classes).map do |item|
              parse_class(item, coverage_report, context)
            end

            # Remove these filenames from the paths to avoid conflict
            # with other packages that may contain the same class filenames
            remove_matched_filenames(matched_filenames, context)
          end

          def remove_matched_filenames(filenames, context)
            return unless context[:paths]

            filenames.each { |f| context[:paths].delete(f) }
          end

          def parse_class(file, coverage_report, context)
            return unless file["filename"].present? && file["lines"].present?

            parsed_lines = parse_lines(file["lines"])
            filename = determine_filename(file["filename"], context)

            coverage_report.add_file(filename, Hash[parsed_lines]) if filename

            filename
          end

          def parse_lines(lines)
            line_array = Array.wrap(lines["line"])

            line_array.map do |line|
              # Using `Integer()` here to raise exception on invalid values
              [Integer(line["number"]), Integer(line["hits"])]
            end
          rescue StandardError
            raise InvalidLineInformationError, "Line information had invalid values"
          end

          def determine_filename(filename, context)
            return filename unless context[:sources].any?

            full_filename = nil

            context[:sources].each_with_index do |source, index|
              break if index >= MAX_SOURCES
              break if full_filename = check_source(source, filename, context)
            end

            full_filename
          end

          def check_source(source, filename, context)
            full_path = File.join(source, filename)

            return full_path if context[:paths].include?(full_path)
          end
        end
      end
    end
  end
end
