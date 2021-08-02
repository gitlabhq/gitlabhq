# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class SecretDetection < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.2"

          private

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::SecretDetection.new(
              file_path: location_data['file'],
              start_line: location_data['start_line'],
              end_line: location_data['end_line'],
              class_name: location_data['class'],
              method_name: location_data['method']
            )
          end
        end
      end
    end
  end
end
