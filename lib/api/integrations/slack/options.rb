# frozen_string_literal: true

module API
  # This API endpoint handles options payloads sent from Slack.
  # See https://api.slack.com/reference/block-kit/block-elements#external_select.
  class Integrations
    module Slack
      class Options < ::API::Base
        include Slack::Concerns::VerifiesRequest

        feature_category :integrations

        namespace 'integrations/slack' do
          post :options, urgency: :low do
            service_params = Gitlab::Json.parse(params[:payload]).deep_symbolize_keys!
            response = ::Integrations::SlackOptionService.new(service_params).execute

            status :ok

            response.payload
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e)

            no_content!
          end
        end
      end
    end
  end
end
