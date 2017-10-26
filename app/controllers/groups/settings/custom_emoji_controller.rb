module Groups
  module Settings
    class CustomEmojiController < Groups::ApplicationController
      before_action :authorize_admin_group!

      def index
        @custom_emoji = @group.custom_emoji
      end

      def new
        @custom_emoji = @group.custom_emoji.new
      end

      def create
        @custom_emoji = @group.custom_emoji.new(custom_emoji_params)

        if @custom_emoji.save
          redirect_to group_settings_custom_emoji_index_path(@group)
        else
          render :new
        end
      end

      def destroy
        @group.custom_emoji.find_by(id: params[:id])&.destroy!

        redirect_to group_settings_custom_emoji_index_path(@group), status: 302
      end

      private

      def custom_emoji_params
        params.require(:custom_emoji).permit(:name, :file, :group_id)
      end
    end
  end
end
