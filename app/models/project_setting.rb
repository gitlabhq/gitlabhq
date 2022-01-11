# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  belongs_to :project, inverse_of: :project_setting

  enum squash_option: {
    never: 0,
    always: 1,
    default_on: 2,
    default_off: 3
  }, _prefix: 'squash'

  self.primary_key = :project_id

  validates :merge_commit_template, length: { maximum: 500 }
  validates :squash_commit_template, length: { maximum: 500 }

  def squash_enabled_by_default?
    %w[always default_on].include?(squash_option)
  end

  def squash_readonly?
    %w[always never].include?(squash_option)
  end

  validate :validates_mr_default_target_self

  private

  def validates_mr_default_target_self
    if mr_default_target_self_changed? && !project.forked?
      errors.add :mr_default_target_self, _('This setting is allowed for forked projects only')
    end
  end
end

ProjectSetting.prepend_mod
