module EE
  module Gitlab
    module ExternalAuthorization
      extend Config

      RequestFailed = Class.new(StandardError)

      def self.access_allowed?(user, label, project_path = nil)
        return true unless perform_check?
        return false unless user

        access_for_user_to_label(user, label, project_path).has_access?
      end

      def self.rejection_reason(user, label)
        return nil unless enabled?
        return nil unless user

        access_for_user_to_label(user, label, nil).reason
      end

      def self.access_for_user_to_label(user, label, project_path)
        if RequestStore.active?
          RequestStore.fetch("external_authorisation:user-#{user.id}:label-#{label}") do
            load_access(user, label, project_path)
          end
        else
          load_access(user, label, project_path)
        end
      end

      def self.load_access(user, label, project_path)
        access = EE::Gitlab::ExternalAuthorization::Access.new(user, label).load!
        ::EE::Gitlab::ExternalAuthorization::Logger.log_access(access, project_path)

        access
      end
    end
  end
end
