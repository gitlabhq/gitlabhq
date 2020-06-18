# frozen_string_literal: true

class ProjectCiCdSetting < ApplicationRecord
  belongs_to :project, inverse_of: :ci_cd_settings

  DEFAULT_GIT_DEPTH = 50

  before_create :set_default_git_depth

  validates :default_git_depth,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    },
    allow_nil: true

  default_value_for :forward_deployment_enabled, true

  def forward_deployment_enabled?
    super && ::Feature.enabled?(:forward_deployment_enabled, project, default_enabled: true)
  end

  private

  def set_default_git_depth
    self.default_git_depth ||= DEFAULT_GIT_DEPTH
  end
end

ProjectCiCdSetting.prepend_if_ee('EE::ProjectCiCdSetting')
