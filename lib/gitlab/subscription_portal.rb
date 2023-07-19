# frozen_string_literal: true

module Gitlab
  module SubscriptionPortal
    def self.payment_validation_form_id
      "payment_method_validation"
    end

    def self.registration_validation_form_id
      "cc_registration_validation"
    end

    def self.subscription_portal_admin_email
      ENV.fetch('SUBSCRIPTION_PORTAL_ADMIN_EMAIL', 'gl_com_api@gitlab.com')
    end

    def self.subscription_portal_admin_token
      ENV.fetch('SUBSCRIPTION_PORTAL_ADMIN_TOKEN', 'customer_admin_token')
    end

    def self.renewal_service_email
      'renewals-service@customers.gitlab.com'
    end

    def self.default_staging_customer_portal_url
      'https://customers.staging.gitlab.com'
    end

    def self.default_production_customer_portal_url
      'https://customers.gitlab.com'
    end
  end
end

Gitlab::SubscriptionPortal.prepend_mod
Gitlab::SubscriptionPortal::PAYMENT_VALIDATION_FORM_ID = Gitlab::SubscriptionPortal.payment_validation_form_id.freeze
Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL = Gitlab::SubscriptionPortal.renewal_service_email.freeze
Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID = Gitlab::SubscriptionPortal.registration_validation_form_id.freeze
Gitlab::SubscriptionPortal::SUBSCRIPTION_PORTAL_ADMIN_EMAIL = Gitlab::SubscriptionPortal.subscription_portal_admin_email.freeze
Gitlab::SubscriptionPortal::SUBSCRIPTION_PORTAL_ADMIN_TOKEN = Gitlab::SubscriptionPortal.subscription_portal_admin_token.freeze
