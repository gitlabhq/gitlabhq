# frozen_string_literal: true

module Integrations
  module HasWebHook
    extend ActiveSupport::Concern

    included do
      after_save :update_web_hook!, if: :activated?
    end

    # Return the URL to be used for the webhook.
    def hook_url
      raise NotImplementedError
    end

    # Return whether the webhook should use SSL verification.
    def hook_ssl_verification
      true
    end

    # Create or update the webhook, raising an exception if it cannot be saved.
    def update_web_hook!
      hook = service_hook || build_service_hook
      hook.url = hook_url if hook.url != hook_url # avoid reencryption
      hook.enable_ssl_verification = hook_ssl_verification
      hook.save! if hook.changed?
      hook
    end

    # Execute the webhook, creating it if necessary.
    def execute_web_hook!(*args)
      update_web_hook!
      service_hook.execute(*args)
    end
  end
end
