module EE
  module Gitlab
    module ExternalAuthorization
      RequestFailed = Class.new(StandardError)

      def self.access_allowed?(user, label)
        return true unless enabled?
        return false unless user

        access_for_user_to_label(user, label).has_access?
      end

      def self.rejection_reason(user, label)
        return nil unless enabled?
        return nil unless user

        access_for_user_to_label(user, label).reason
      end

      def self.access_for_user_to_label(user, label)
        if RequestStore.active?
          RequestStore.fetch("external_authorisation:user-#{user.id}:label-#{label}") do
            EE::Gitlab::ExternalAuthorization::Access.new(user, label).load!
          end
        else
          EE::Gitlab::ExternalAuthorization::Access.new(user, label).load!
        end
      end

      def self.enabled?
        ::Gitlab::CurrentSettings
          .current_application_settings
          .external_authorization_service_enabled?
      end

      def self.service_url
        ::Gitlab::CurrentSettings
          .current_application_settings
          .external_authorization_service_url
      end

      def self.timeout
        ::Gitlab::CurrentSettings
          .current_application_settings
          .external_authorization_service_timeout
      end
    end
  end
end
