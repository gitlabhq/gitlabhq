# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  include IgnorableColumns

  ignore_column :allow_editing_commit_messages, remove_with: '14.4', remove_after: '2021-09-10'

  belongs_to :project, inverse_of: :project_setting

  enum squash_option: {
    never: 0,
    always: 1,
    default_on: 2,
    default_off: 3
  }, _prefix: 'squash'

  self.primary_key = :project_id

  def squash_enabled_by_default?
    %w[always default_on].include?(squash_option)
  end

  def squash_readonly?
    %w[always never].include?(squash_option)
  end
end

ProjectSetting.prepend_mod
