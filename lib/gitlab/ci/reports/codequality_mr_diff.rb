# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CodequalityMrDiff
        attr_reader :files

        def initialize(new_errors)
          @new_errors = new_errors
          @files = {}
          build_report!
        end

        private

        def build_report!
          codequality_files = @new_errors.each_with_object({}) do |degradation, codequality_files|
            unless codequality_files[degradation.dig(:location, :path)].present?
              codequality_files[degradation.dig(:location, :path)] = []
            end

            build_mr_diff_payload(codequality_files, degradation)
          end

          @files = codequality_files
        end

        def build_mr_diff_payload(codequality_files, degradation)
          codequality_files[degradation.dig(:location, :path)] << {
            line: degradation.dig(:location, :lines, :begin) || degradation.dig(:location, :positions, :begin, :line),
            description: degradation[:description],
            severity: degradation[:severity],
            engine_name: degradation[:engine_name],
            categories: degradation[:categories],
            content: convert_body(degradation[:content]),
            location: degradation[:location],
            other_locations: degradation[:other_locations],
            type: degradation[:type]
          }
        end

        def convert_body(content)
          content["body"] = ::MarkupHelper.markdown(content["body"])
          content
        end
      end
    end
  end
end
