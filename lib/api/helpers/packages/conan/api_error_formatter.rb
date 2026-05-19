# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Conan
        module ApiErrorFormatter
          # Conan's response_to_str() natively parses the "errors" array format,
          # producing clean user-facing messages instead of raw JSON dumps.
          def render_structured_api_error!(hash, status)
            if Feature.enabled?(:conan_structured_error_responses, Feature.current_request)
              status_code = Rack::Utils.status_code(status)

              if status_code >= 400
                hash = hash.with_indifferent_access
                stripped = hash[:message].to_s.sub(/\A#{status_code}\s+/, '')
                hash[:errors] = [{ 'status' => status_code, 'message' => stripped }]
              end
            end

            super
          end
        end
      end
    end
  end
end
