# frozen_string_literal: true

module VsCode
  module Settings
    class VsCodeSetting < ApplicationRecord
      include ::VsCode::Settings

      belongs_to :user, inverse_of: :vscode_settings

      validates :settings_context_hash,
        length: { maximum: 255 },
        uniqueness: { scope: [:user_id, :setting_type] }
      validate :settings_context_hash_check

      validates :setting_type, presence: true,
        inclusion: { in: SETTINGS_TYPES },
        uniqueness: { scope: [:user_id, :settings_context_hash] }
      validates :content, :uuid, :version, presence: true

      scope :by_setting_types, ->(setting_types, settings_context_hash = nil) {
        includes_extensions = setting_types.include?(EXTENSIONS)

        if setting_types.one? && includes_extensions
          # Query for extensions setting type
          where(setting_type: EXTENSIONS, settings_context_hash: settings_context_hash)
        elsif includes_extensions
          # Separate queries for 'extensions' and other setting types, then combine
          non_extensions_setting_types = setting_types.reject { |setting_type| setting_type == EXTENSIONS }

          non_extensions_query = where(setting_type: non_extensions_setting_types)
          extensions_query = where(setting_type: EXTENSIONS, settings_context_hash: settings_context_hash)
          non_extensions_query.or(extensions_query)
        else
          # Query for all non-extensions setting types
          where(setting_type: setting_types)
        end
      }
      scope :by_user, ->(user) { where(user: user) }

      private

      def settings_context_hash_check
        return unless setting_type != EXTENSIONS && !settings_context_hash.nil?

        errors.add(:settings_context_hash, 'must be blank for non extensions setting type')
      end
    end
  end
end
