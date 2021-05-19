# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    def self.default_subscriptions_url
      ::Gitlab.dev_or_test_env? ? 'https://customers.stg.gitlab.com' : 'https://customers.gitlab.com'
    end

    def self.subscriptions_url
      ENV.fetch('CUSTOMER_PORTAL_URL', default_subscriptions_url)
    end

    def self.payment_form_url
      "#{self.subscriptions_url}/payment_forms/cc_validation"
    end
  end
end

Gitlab::SubscriptionPortal.prepend_mod
Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL = Gitlab::SubscriptionPortal.subscriptions_url.freeze
Gitlab::SubscriptionPortal::PAYMENT_FORM_URL = Gitlab::SubscriptionPortal.payment_form_url.freeze
