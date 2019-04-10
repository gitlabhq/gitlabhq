# frozen_string_literal: true

module Gitlab
  module ExternalAuthorization
    extend ExternalAuthorization::Config

    RequestFailed = Class.new(StandardError)

    def self.access_allowed?(user, label, project_path = nil)
      return true unless perform_check?
      return false unless user

      access_for_user_to_label(user, label, project_path).has_access?
    end

    def self.rejection_reason(user, label)
      return unless enabled?
      return unless user

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
      access = ::Gitlab::ExternalAuthorization::Access.new(user, label).load!
      ::Gitlab::ExternalAuthorization::Logger.log_access(access, project_path)

      access
    end
  end
end
