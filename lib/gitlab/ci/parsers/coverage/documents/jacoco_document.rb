# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        module Documents
          class JacocoDocument < Nokogiri::XML::SAX::Document
            PATH_TAGS = %w[group package sourcefile].freeze

            def initialize(coverage_report, merge_request_file_paths)
              @coverage_report = coverage_report
              @merge_request_file_paths = merge_request_file_paths

              @current_path_array = []
            end

            def error(error)
              raise Jacoco::InvalidXMLError, "XML parsing failed with error: #{error}"
            end

            def start_element(node_name, attrs = [])
              return unless node_name

              node_attrs = attrs.to_h

              if PATH_TAGS.include?(node_name) && node_attrs["name"].present?
                current_path_array << unixify(node_attrs["name"])
              elsif node_name == 'line'
                parse_line(node_attrs)
              end
            end

            def end_element(node_name)
              # remove the element from the current path, as if leaving the current directory
              return unless PATH_TAGS.include?(node_name)

              current_path_array.pop
            end

            private

            attr_accessor :coverage_report, :merge_request_file_paths,
              :current_path_array

            def parse_line(node_attrs)
              coverage_data = { node_attrs.fetch('nr').to_i => node_attrs.fetch('ci').to_i }
              coverage_report.add_file(matched_full_path, coverage_data)
            rescue KeyError
              raise Jacoco::InvalidLineInformationError, "Line information had invalid attributes"
            end

            def current_path
              File.join(current_path_array)
            end

            # Jacoco reports only provide the relative path
            # so we need to match the files against the ones changed on the MR
            # and provide the full path in our reports
            def matched_full_path
              matched_path = merge_request_file_paths.find do |full_path|
                full_path.include?(current_path)
              end

              Gitlab::AppLogger.info(message: "Missing merge request changes for #{current_path}") unless matched_path

              matched_path
            end

            def unixify(path)
              path.tr('\\', '/')
            end
          end
        end
      end
    end
  end
end
