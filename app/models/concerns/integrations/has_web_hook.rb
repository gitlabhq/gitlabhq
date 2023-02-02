# frozen_string_literal: true

module Integrations
  module HasWebHook
    extend ActiveSupport::Concern

    included do
      after_save :update_web_hook!, if: :activated?
      has_one :service_hook, inverse_of: :integration, foreign_key: :integration_id
    end

    # Return the URL to be used for the webhook.
    def hook_url
      raise NotImplementedError
    end

    # Return the url variables to be used for the webhook.
    def url_variables
      raise NotImplementedError
    end

    # Return whether the webhook should use SSL verification.
    def hook_ssl_verification
      if respond_to?(:enable_ssl_verification)
        enable_ssl_verification
      else
        true
      end
    end

    # Create or update the webhook, raising an exception if it cannot be saved.
    def update_web_hook!
      hook = service_hook || build_service_hook

      # Avoid reencryption
      hook.url = hook_url if hook.url != hook_url
      hook.url_variables = url_variables if hook.url_variables != url_variables

      hook.enable_ssl_verification = hook_ssl_verification
      hook.save! if hook.changed?
      hook
    end

    # Execute the webhook, creating it if necessary.
    def execute_web_hook!(...)
      update_web_hook!
      service_hook.execute(...)
    end
  end
end
