# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        module Documents
          class CoberturaDocument < Nokogiri::XML::SAX::Document
            GO_SOURCE_PATTERN = '/usr/local/go/src'
            MAX_SOURCES = 100

            def initialize(coverage_report, project_path, worktree_paths)
              @coverage_report = coverage_report
              @project_path = project_path
              @paths = worktree_paths&.to_set

              @matched_filenames = []
              @parsed_lines = []
              @sources = []
            end

            def error(error)
              raise Cobertura::InvalidXMLError, "XML parsing failed with error: #{error}"
            end

            def start_element(node_name, attrs = [])
              return unless node_name

              self.node_name = node_name
              node_attrs = Hash[attrs]

              if node_name == 'class' && node_attrs["filename"].present?
                self.filename = determine_filename(node_attrs["filename"])
                self.matched_filenames << filename if filename
              elsif node_name == 'line'
                self.parsed_lines << parse_line(node_attrs)
              end
            end

            def characters(node_content)
              if node_name == 'source'
                parse_source(node_content)
              end
            end

            def end_element(node_name)
              if node_name == "package"
                remove_matched_filenames
              elsif node_name == "class" && filename && parsed_lines.present?
                coverage_report.add_file(filename, Hash[parsed_lines])
                self.filename = nil
                self.parsed_lines = []
              end
            end

            private

            attr_accessor :coverage_report, :project_path, :paths, :sources, :node_name, :filename, :parsed_lines, :matched_filenames

            def parse_line(line)
              [Integer(line["number"]), Integer(line["hits"])]
            rescue StandardError
              raise Cobertura::InvalidLineInformationError, "Line information had invalid values"
            end

            def parse_source(node)
              return unless project_path && paths && node.exclude?(GO_SOURCE_PATTERN)

              source = build_source_path(node)
              self.sources << source if source.present?
            end

            def build_source_path(node)
              # | raw source                  | extracted  |
              # |-----------------------------|------------|
              # | /builds/foo/test/SampleLib/ | SampleLib/ |
              # | /builds/foo/test/something  | something  |
              # | /builds/foo/test/           | nil        |
              # | /builds/foo/test            | nil        |
              # | D:\builds\foo\bar\app\      | app\       |
              unixify(node).split("#{project_path}/", 2)[1]
            end

            def unixify(path)
              path.tr('\\', '/')
            end

            def remove_matched_filenames
              return unless paths

              matched_filenames.each { |f| paths.delete(f) }
            end

            def determine_filename(filename)
              filename = unixify(filename)
              return filename unless sources.any?

              full_filename = nil

              sources.each_with_index do |source, index|
                break if index >= MAX_SOURCES
                break if full_filename = check_source(source, filename)
              end

              full_filename
            end

            def check_source(source, filename)
              full_path = File.join(source, filename)

              return full_path if paths.include?(full_path)
            end
          end
        end
      end
    end
  end
end
