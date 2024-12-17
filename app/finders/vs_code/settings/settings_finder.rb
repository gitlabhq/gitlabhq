# frozen_string_literal: true

module VsCode
  module Settings
    class SettingsFinder
      def initialize(current_user:, setting_types:, settings_context_hash: nil)
        @current_user = current_user
        @setting_types = setting_types
        @settings_context_hash = settings_context_hash
      end

      def execute
        relation = User.find(current_user.id).vscode_settings

        return relation unless setting_types.present?

        relation.by_setting_types(setting_types, settings_context_hash)
      end

      private

      attr_accessor :current_user, :setting_types, :settings_context_hash
    end
  end
end
