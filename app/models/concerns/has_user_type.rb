# frozen_string_literal: true

module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = {
    human_deprecated: nil,
    human: 0,
    support_bot: 1,
    alert_bot: 2,
    visual_review_bot: 3,
    service_user: 4,
    ghost: 5,
    project_bot: 6,
    migration_bot: 7,
    security_bot: 8,
    automation_bot: 9,
    security_policy_bot: 10, # Currently not in use. See https://gitlab.com/gitlab-org/gitlab/-/issues/384174
    admin_bot: 11,
    suggested_reviewers_bot: 12,
    service_account: 13,
    llm_bot: 14
  }.with_indifferent_access.freeze

  BOT_USER_TYPES = %w[
    alert_bot
    project_bot
    support_bot
    visual_review_bot
    migration_bot
    security_bot
    automation_bot
    security_policy_bot
    admin_bot
    suggested_reviewers_bot
    service_account
    llm_bot
  ].freeze

  # `service_account` allows instance/namespaces to configure a user for external integrations/automations
  # `service_user` is an internal, `gitlab-com`-specific user type for integrations like suggested reviewers
  NON_INTERNAL_USER_TYPES = %w[human human_deprecated project_bot service_user service_account].freeze
  INTERNAL_USER_TYPES = (USER_TYPES.keys - NON_INTERNAL_USER_TYPES).freeze

  included do
    enum user_type: USER_TYPES

    scope :humans, -> { where(user_type: :human).or(where(user_type: :human_deprecated)) }
    # Override default scope to include temporary human type. See https://gitlab.com/gitlab-org/gitlab/-/issues/386474
    scope :human, -> { humans }
    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { humans.or(where(user_type: USER_TYPES.keys - BOT_USER_TYPES)) }
    scope :non_internal, -> { humans.or(where(user_type: NON_INTERNAL_USER_TYPES)) }
    scope :without_ghosts, -> { humans.or(where(user_type: USER_TYPES.keys - ['ghost'])) }
    scope :without_project_bot, -> { humans.or(where(user_type: USER_TYPES.keys - ['project_bot'])) }
    scope :human_or_service_user, -> { humans.or(where(user_type: :service_user)) }

    def human?
      super || human_deprecated? || user_type.nil?
    end
  end

  def bot?
    BOT_USER_TYPES.include?(user_type)
  end

  def internal?
    INTERNAL_USER_TYPES.include?(user_type)
  end

  def redacted_name(viewing_user)
    return self.name unless self.project_bot?

    return self.name if self.groups.any? && viewing_user&.can?(:read_group, self.groups.first)

    return self.name if viewing_user&.can?(:read_project, self.projects.first)

    # If the requester does not have permission to read the project bot name,
    # the API returns an arbitrary string. UI changes will be addressed in a follow up issue:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/346058
    '****'
  end
end
