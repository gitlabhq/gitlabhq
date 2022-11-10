# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Codequality
        class CodeClimate
          def parse!(json_data, codequality_report, metadata = {})
            root = Gitlab::Json.parse(json_data)

            parse_all(root, codequality_report, metadata)
          rescue JSON::ParserError => e
            codequality_report.set_error_message("JSON parsing failed: #{e}")
          end

          private

          def parse_all(root, codequality_report, metadata)
            return unless root.present?

            root.each do |degradation|
              break unless codequality_report.valid_degradation?(degradation)

              degradation['web_url'] = web_url(degradation, metadata)
              codequality_report.add_degradation(degradation)
            end
          end

          def web_url(degradation, metadata)
            return unless metadata[:project].present? && metadata[:commit_sha].present?

            path = degradation.dig('location', 'path')
            line = degradation.dig('location', 'lines', 'begin') ||
              degradation.dig('location', 'positions', 'begin', 'line')
            "#{Routing.url_helpers.project_blob_url(
              metadata[:project], File.join(metadata[:commit_sha], path))}#L#{line}"
          end
        end
      end
    end
  end
end
