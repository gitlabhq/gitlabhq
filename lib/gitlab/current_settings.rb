# frozen_string_literal: true

module Gitlab
  module CurrentSettings
    class << self
      def signup_disabled?
        !signup_enabled?
      end

      def signup_limited?
        domain_allowlist.present? || email_restrictions_enabled? || require_admin_approval_after_user_signup? || user_default_external?
      end

      def current_application_settings
        Gitlab::SafeRequestStore.fetch(:current_application_settings) { Gitlab::ApplicationSettingFetcher.current_application_settings }
      end

      def current_application_settings?
        Gitlab::SafeRequestStore.exist?(:current_application_settings) || Gitlab::ApplicationSettingFetcher.current_application_settings?
      end

      def expire_current_application_settings
        Gitlab::ApplicationSettingFetcher.expire_current_application_settings
        Gitlab::SafeRequestStore.delete(:current_application_settings)
      end

      # rubocop:disable GitlabSecurity/PublicSend -- Method calls are forwarded to one of the setting classes
      def method_missing(name, *args, **kwargs, &block)
        application_settings = current_application_settings

        return application_settings.send(name, *args, **kwargs, &block) if application_settings.respond_to?(name)

        if respond_to_organization_setting?(name, false)
          return ::Organizations::OrganizationSetting.for(::Current.organization_id).send(name, *args, **kwargs, &block)
        end

        super
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def respond_to_missing?(name, include_private = false)
        current_application_settings.respond_to?(name, include_private) || respond_to_organization_setting?(name, include_private) || super
      end

      def respond_to_organization_setting?(name, include_private)
        return false unless ::Current.organization_assigned

        ::Organizations::OrganizationSetting.for(::Current.organization_id).respond_to?(name, include_private)
      end
    end
  end
end
