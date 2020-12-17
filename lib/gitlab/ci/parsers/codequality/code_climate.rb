# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Codequality
        class CodeClimate
          def parse!(json_data, codequality_report)
            root = Gitlab::Json.parse(json_data)

            parse_all(root, codequality_report)
          rescue JSON::ParserError => e
            codequality_report.set_error_message("JSON parsing failed: #{e}")
          end

          private

          def parse_all(root, codequality_report)
            return unless root.present?

            root.each do |degradation|
              break unless codequality_report.add_degradation(degradation)
            end
          end
        end
      end
    end
  end
end
