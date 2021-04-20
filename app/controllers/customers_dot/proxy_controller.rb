# frozen_string_literal: true

module CustomersDot
  class ProxyController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    feature_category :purchase

    BASE_URL = Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL

    def graphql
      response = Gitlab::HTTP.post("#{BASE_URL}/graphql",
        body: request.raw_post,
        headers: { 'Content-Type' => 'application/json' }
      )

      render json: response.body, status: response.code
    end
  end
end
