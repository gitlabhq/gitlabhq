module EE
  # Group EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Group` model
  module Group
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      has_many :epics

      has_one :saml_provider

      has_many :ldap_group_links, foreign_key: 'group_id', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :hooks, dependent: :destroy, class_name: 'GroupHook' # rubocop:disable Cop/ActiveRecordDependent

      # We cannot simply set `has_many :audit_events, as: :entity, dependent: :destroy`
      # here since Group inherits from Namespace, the entity_type would be set to `Namespace`.
      has_many :audit_events, -> { where(entity_type: ::Group) }, foreign_key: 'entity_id'

      validates :repository_size_limit,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

      scope :where_group_links_with_provider, ->(provider) do
        joins(:ldap_group_links).where(ldap_group_links: { provider: provider })
      end

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

    def human_ldap_access
      ::Gitlab::Access.options_with_owner.key(ldap_access)
    end

    # NOTE: Backwards compatibility with old ldap situation
    def ldap_cn
      ldap_group_links.first.try(:cn)
    end

    def ldap_access
      ldap_group_links.first.try(:group_access)
    end

    override :ldap_synced?
    def ldap_synced?
      (::Gitlab.config.ldap.enabled && ldap_group_links.any?(&:active?)) || super
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

    def actual_size_limit
      return ::Gitlab::CurrentSettings.repository_size_limit if repository_size_limit.nil?

      repository_size_limit
    end

    def first_non_empty_project
      projects.detect { |project| !project.empty_repo? }
    end
  end
end
