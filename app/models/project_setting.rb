# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  include IgnorableColumns

  ignore_column :show_diff_preview_in_email, remove_with: '14.10', remove_after: '2022-03-22'

  belongs_to :project, inverse_of: :project_setting

  enum squash_option: {
    never: 0,
    always: 1,
    default_on: 2,
    default_off: 3
  }, _prefix: 'squash'

  self.primary_key = :project_id

  validates :merge_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }
  validates :squash_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }

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
