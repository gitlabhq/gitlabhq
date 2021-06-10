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
    automation_bot: 9
  }.with_indifferent_access.freeze

  BOT_USER_TYPES = %w[alert_bot project_bot support_bot visual_review_bot migration_bot security_bot automation_bot].freeze
  NON_INTERNAL_USER_TYPES = %w[human project_bot service_user].freeze
  INTERNAL_USER_TYPES = (USER_TYPES.keys - NON_INTERNAL_USER_TYPES).freeze

  included do
    scope :humans, -> { where(user_type: :human) }
    scope :bots, -> { where(user_type: BOT_USER_TYPES) }
    scope :without_bots, -> { humans.or(where.not(user_type: BOT_USER_TYPES)) }
    scope :bots_without_project_bot, -> { where(user_type: BOT_USER_TYPES - ['project_bot']) }
    scope :non_internal, -> { humans.or(where(user_type: NON_INTERNAL_USER_TYPES)) }
    scope :without_ghosts, -> { humans.or(where.not(user_type: :ghost)) }
    scope :without_project_bot, -> { humans.or(where.not(user_type: :project_bot)) }

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
end
