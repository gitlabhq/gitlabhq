# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Maven
        module ApiErrorFormatter
          extend ::Gitlab::Utils::Override
          include ::API::Helpers::Packages::ErrorMessage

          PROBLEM_DETAILS_CONTENT_TYPE = 'application/problem+json'

          override :render_structured_api_error!
          def render_structured_api_error!(hash, status)
            status_code = Rack::Utils.status_code(status)

            unless problem_details_enabled?(status_code)
              # Keep `error` in sync with `message` for clients and request specs that expect
              # Grape's default `error!` (string) shape: top-level "error" key.
              message = hash['message']
              hash = hash.merge('error' => message) if message.is_a?(String) && message.present? && !hash['error']

              return super
            end

            message_string = message_string_for_detail(hash['message'])
            detail = extract_detail(message_string)
            body = build_problem_details_body(status_code, detail)
            set_status_code_in_env(status_code)
            error!(body, status_code, 'Content-Type' => PROBLEM_DETAILS_CONTENT_TYPE)
          end

          private

          def problem_details_enabled?(status_code)
            status_code >= 400 && Feature.enabled?(:maven_problem_details_errors, Feature.current_request)
          end

          def message_string_for_detail(message)
            case message
            when String, nil
              message
            when Hash
              (message['error'] || message[:error] || message['message'] || message[:message]).to_s
            else
              message.to_s
            end
          end

          def extract_detail(message)
            return if message.blank?
            return message unless message.is_a?(String)

            error_message_detail(message) || message
          end

          def build_problem_details_body(status_code, detail)
            body = {
              'type' => 'about:blank',
              'status' => status_code,
              'title' => Rack::Utils::HTTP_STATUS_CODES[status_code]
            }

            if detail.present?
              body['detail'] = detail
              # Same compatibility as the non-problem-details branch: consumers may read `error`.
              body['error'] = detail
            end

            body
          end
        end
      end
    end
  end
end
