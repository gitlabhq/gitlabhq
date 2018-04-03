module EE
  # Group EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Group` model
  module Group
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    included do
      has_many :epics

      has_one :saml_provider

      state_machine :ldap_sync_status, namespace: :ldap_sync, initial: :ready do
        state :ready
        state :started
        state :pending
        state :failed

        event :pending do
          transition [:ready, :failed] => :pending
        end

        event :start do
          transition [:ready, :pending, :failed] => :started
        end

        event :finish do
          transition started: :ready
        end

        event :fail do
          transition started: :failed
        end

        after_transition ready: :started do |group, _|
          group.ldap_sync_last_sync_at = DateTime.now
          group.save
        end

        after_transition started: :ready do |group, _|
          current_time = DateTime.now
          group.ldap_sync_last_update_at = current_time
          group.ldap_sync_last_successful_update_at = current_time
          group.ldap_sync_error = nil
          group.save
        end

        after_transition started: :failed do |group, _|
          group.ldap_sync_last_update_at = DateTime.now
          group.save
        end
      end
    end

    def mark_ldap_sync_as_failed(error_message)
      return false unless ldap_sync_started?

      fail_ldap_sync
      update_column(:ldap_sync_error, ::Gitlab::UrlSanitizer.sanitize(error_message))
    end

    def project_creation_level
      super || ::Gitlab::CurrentSettings.default_project_creation
    end

    override :multiple_issue_boards_available?
    def multiple_issue_boards_available?
      feature_available?(:multiple_group_issue_boards)
    end
  end
end
