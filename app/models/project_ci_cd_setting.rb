# frozen_string_literal: true

class ProjectCiCdSetting < ApplicationRecord
  include ChronicDurationAttribute

  belongs_to :project, inverse_of: :ci_cd_settings

  DEFAULT_GIT_DEPTH = 20

  before_create :set_default_git_depth

  validates :default_git_depth,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    },
    allow_nil: true

  attribute :forward_deployment_enabled, default: true
  attribute :separated_caches, default: true
  validates :merge_trains_skip_train_allowed, inclusion: { in: [true, false] }

  chronic_duration_attr :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval

  def keep_latest_artifacts_available?
    # The project level feature can only be enabled when the feature is enabled instance wide
    Gitlab::CurrentSettings.current_application_settings.keep_latest_artifact? && keep_latest_artifact?
  end

  private

  def set_default_git_depth
    self.default_git_depth ||= DEFAULT_GIT_DEPTH
  end
end

ProjectCiCdSetting.prepend_mod_with('ProjectCiCdSetting')
