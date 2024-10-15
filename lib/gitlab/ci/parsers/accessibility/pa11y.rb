# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Accessibility
        class Pa11y
          def parse!(json_data, accessibility_report)
            root = Gitlab::Json.parse(json_data).with_indifferent_access

            parse_all(root, accessibility_report)
          rescue JSON::ParserError => e
            accessibility_report.set_error_message("JSON parsing failed: #{e}")
          rescue StandardError => e
            accessibility_report.set_error_message("Pa11y parsing failed: #{e}")
          end

          private

          def parse_all(root, accessibility_report)
            return unless root.present?

            root["results"].each do |url, value|
              accessibility_report.add_url(url, value)
            end

            accessibility_report
          end
        end
      end
    end
  end
end
