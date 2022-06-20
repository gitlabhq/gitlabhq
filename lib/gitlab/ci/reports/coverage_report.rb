# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CoverageReport
        attr_reader :files

        def initialize
          @files = {}
        end

        def empty?
          @files.empty?
        end

        def pick(keys)
          coverage_files = files.select do |key|
            keys.include?(key)
          end

          { files: coverage_files }
        end

        def add_file(name, line_coverage)
          if files[name].present?
            line_coverage.each { |line, hits| combine_lines(name, line, hits) }

          else
            files[name] = line_coverage
          end
        end

        private

        def combine_lines(name, line, hits)
          if files[name][line].present?
            files[name][line] += hits

          else
            files[name][line] = hits
          end
        end
      end
    end
  end
end
