# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeSetting < ApplicationRecord
      belongs_to :user, inverse_of: :vscode_settings

      validates :setting_type, presence: true,
        inclusion: { in: SETTINGS_TYPES },
        uniqueness: { scope: :user_id }
      validates :content, presence: true

      scope :by_setting_type, ->(setting_type) { where(setting_type: setting_type) }
      scope :by_user, ->(user) { where(user: user) }
    end
  end
end
