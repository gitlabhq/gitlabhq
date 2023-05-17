# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module IncidentManagement
      class IncidentModalClosedService
        def initialize(params)
          @params = params
        end

        def execute
          begin
            response = close_modal
          rescue *Gitlab::HTTP::HTTP_ERRORS => e
            return ServiceResponse
              .error(message: 'HTTP exception when calling Slack API')
              .track_exception(
                params: params,
                as: e.class
              )
          end

          return ServiceResponse.success if response['ok']

          ServiceResponse.error(
            message: _('Something went wrong while closing the incident form.'),
            payload: response
          ).track_exception(
            response: response.to_h,
            params: params
          )
        end

        private

        attr_accessor :params

        def close_modal
          request_body = Gitlab::Json.dump(close_request_body)
          response_url = params.dig(:view, :private_metadata)

          Gitlab::HTTP.post(response_url, body: request_body, headers: headers)
        end

        def close_request_body
          {
            replace_original: 'true',
            text: _('Incident creation cancelled.')
          }
        end

        def headers
          { 'Content-Type' => 'application/json' }
        end
      end
    end
  end
end
