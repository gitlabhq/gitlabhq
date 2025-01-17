# frozen_string_literal: true

module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = {
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
    security_policy_bot: 10,
    admin_bot: 11,
    suggested_reviewers_bot: 12,
    service_account: 13,
    llm_bot: 14,
    placeholder: 15,
    duo_code_review_bot: 16,
    import_user: 17
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
    duo_code_review_bot
  ].freeze

  # `service_account` allows instance/namespaces to configure a user for external integrations/automations
  # `service_user` is an internal, `gitlab-com`-specific user type for integrations like suggested reviewers
  # Changes to these types might have billing implications, https://docs.gitlab.com/ee/subscriptions/gitlab_com/#billable-users
  NON_INTERNAL_USER_TYPES = %w[human project_bot service_user service_account].freeze
  INTERNAL_USER_TYPES = (USER_TYPES.keys - NON_INTERNAL_USER_TYPES).freeze

  included do
    enum user_type: USER_TYPES

    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { where(user_type: USER_TYPES.keys - BOT_USER_TYPES) }
    scope :non_internal, -> { where(user_type: NON_INTERNAL_USER_TYPES) }
    scope :with_duo_code_review_bot, -> { where(user_type: NON_INTERNAL_USER_TYPES + ['duo_code_review_bot']) }
    scope :without_ghosts, -> { where(user_type: USER_TYPES.keys - ['ghost']) }
    scope :without_project_bot, -> { where(user_type: USER_TYPES.keys - ['project_bot']) }
    scope :without_humans, -> { where(user_type: USER_TYPES.keys - ['human']) }
    scope :human_or_service_user, -> { where(user_type: %i[human service_user]) }
    scope :resource_access_token_bot, -> { where(user_type: 'project_bot') }

    validates :user_type, presence: true
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

  def resource_bot_resource
    return unless project_bot?

    projects&.first || groups&.first
  end

  def resource_bot_owners_and_maintainers
    return [] unless project_bot?

    resource = resource_bot_resource
    return [] unless resource

    return resource.owners_and_maintainers if resource.is_a?(Project)

    resource
      .owners
      .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/436658")
  end
end
