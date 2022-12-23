# frozen_string_literal: true

module HasUserType
  extend ActiveSupport::Concern

  USER_TYPES = {
    human: nil,
    support_bot: 1,
    alert_bot: 2,
    visual_review_bot: 3,
    service_user: 4,
    ghost: 5,
    project_bot: 6,
    migration_bot: 7,
    security_bot: 8,
    automation_bot: 9,
    admin_bot: 11
  }.with_indifferent_access.freeze

  BOT_USER_TYPES = %w[alert_bot project_bot support_bot visual_review_bot migration_bot security_bot automation_bot admin_bot].freeze
  NON_INTERNAL_USER_TYPES = %w[human project_bot service_user].freeze
  INTERNAL_USER_TYPES = (USER_TYPES.keys - NON_INTERNAL_USER_TYPES).freeze

  included do
    scope :humans, -> { where(user_type: :human) }
    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { humans.or(where(user_type: USER_TYPES.keys - BOT_USER_TYPES)) }
    scope :non_internal, -> { humans.or(where(user_type: NON_INTERNAL_USER_TYPES)) }
    scope :without_ghosts, -> { humans.or(where(user_type: USER_TYPES.keys - ['ghost'])) }
    scope :without_project_bot, -> { humans.or(where(user_type: USER_TYPES.keys - ['project_bot'])) }
    scope :human_or_service_user, -> { humans.or(where(user_type: :service_user)) }

    enum user_type: USER_TYPES

    def human?
      super || user_type.nil?
    end
  end

  def bot?
    BOT_USER_TYPES.include?(user_type)
  end

  # The explicit check for project_bot will be removed with Bot Categorization
  # Ref: https://gitlab.com/gitlab-org/gitlab/-/issues/213945
  def internal?
    ghost? || (bot? && !project_bot?)
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
