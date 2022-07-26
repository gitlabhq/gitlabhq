# frozen_string_literal: true

module QA
  module Vendor
    module Jenkins
      module Helpers
        private

        def try_parse(string)
          JSON.parse(string)
        rescue StandardError => _e
          nil
        end

        def check_network_error(response)
          raise NetworkError, "#{response.code} - #{response.body}" if response.code >= 400
        end

        def handle_json_response(response)
          check_network_error(response)
          set_cookies(response)

          unless (data = try_parse(response.body))
            raise NotParseableError, "Code: #{response.code}\nBody: #{response.body}"
          end

          data
        end

        def set_cookies(response)
          self.cookies = response.cookies
        end
      end
    end
  end
end
