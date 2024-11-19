# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeSetting < ApplicationRecord
      belongs_to :user, inverse_of: :vscode_settings

      validates :settings_context_hash,
        length: { maximum: 255 },
        uniqueness: { scope: [:user_id, :setting_type] }
      validates :setting_type, presence: true,
        inclusion: { in: SETTINGS_TYPES },
        uniqueness: { scope: [:user_id, :settings_context_hash] }
      validates :content, :uuid, :version, presence: true

      scope :by_setting_type, ->(setting_type) { where(setting_type: setting_type) }
      scope :by_user, ->(user) { where(user: user) }
    end
  end
end
