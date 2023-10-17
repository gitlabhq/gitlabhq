# frozen_string_literal: true

module VsCode
  module Settings
    class SettingsFinder
      def initialize(current_user, setting_types)
        @current_user = current_user
        @setting_types = setting_types
      end

      def execute
        relation = User.find(current_user.id).vscode_settings
        return relation unless setting_types.present?

        relation.by_setting_type(setting_types)
      end

      private

      attr_accessor :current_user, :setting_types
    end
  end
end
