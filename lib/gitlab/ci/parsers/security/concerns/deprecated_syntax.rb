# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Concerns
          module DeprecatedSyntax
            extend ActiveSupport::Concern

            included do
              extend ::Gitlab::Utils::Override

              override :parse_report
            end

            def report_data
              @report_data ||= begin
                data = super

                if data.is_a?(Array)
                  data = {
                    "version" => self.class::DEPRECATED_REPORT_VERSION,
                    "vulnerabilities" => data
                  }
                end

                data
              end
            end
          end
        end
      end
    end
  end
end
