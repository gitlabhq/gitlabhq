# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    def self.default_subscriptions_url
      ::Gitlab.dev_or_test_env? ? 'https://customers.stg.gitlab.com' : 'https://customers.gitlab.com'
    end

    SUBSCRIPTIONS_URL = ENV.fetch('CUSTOMER_PORTAL_URL', default_subscriptions_url).freeze
  end
end
