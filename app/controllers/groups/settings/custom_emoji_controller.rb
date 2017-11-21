module Groups
  module Settings
    class CustomEmojiController < Groups::ApplicationController
      include CustomEmojiSettings

      before_action :authorize_admin_group!

      private

      def namespace
        @group
      end

      def custom_emoji_index_path
        group_settings_custom_emoji_index_path(@group)
      end
    end
  end
end
