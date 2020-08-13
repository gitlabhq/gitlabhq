# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        class Cobertura
          CoberturaParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(xml_data, coverage_report)
            root = Hash.from_xml(xml_data)

            parse_all(root, coverage_report)
          rescue Nokogiri::XML::SyntaxError
            raise CoberturaParserError, "XML parsing failed"
          rescue
            raise CoberturaParserError, "Cobertura parsing failed"
          end

          private

          def parse_all(root, coverage_report)
            return unless root.present?

            root.each do |key, value|
              parse_node(key, value, coverage_report)
            end
          end

          def parse_node(key, value, coverage_report)
            return if key == 'sources'

            if key == 'class'
              Array.wrap(value).each do |item|
                parse_class(item, coverage_report)
              end
            elsif value.is_a?(Hash)
              parse_all(value, coverage_report)
            elsif value.is_a?(Array)
              value.each do |item|
                parse_all(item, coverage_report)
              end
            end
          end

          def parse_class(file, coverage_report)
            return unless file["filename"].present? && file["lines"].present?

            parsed_lines = parse_lines(file["lines"])

            coverage_report.add_file(file["filename"], Hash[parsed_lines])
          end

          def parse_lines(lines)
            line_array = Array.wrap(lines["line"])

            line_array.map do |line|
              # Using `Integer()` here to raise exception on invalid values
              [Integer(line["number"]), Integer(line["hits"])]
            end
          end
        end
      end
    end
  end
end
