class Profiles::CustomEmojiController < Profiles::ApplicationController
  def index
    @custom_emoji = namespace.custom_emoji
  end

  def new
    @custom_emoji = namespace.custom_emoji.new
  end

  def create
    @custom_emoji = namespace.custom_emoji.new(custom_emoji_params)

    if @custom_emoji.save
      redirect_to profile_custom_emoji_index_path
    else
      render :new
    end
  end

  def destroy
    namespace.custom_emoji.find_by(id: params[:id])&.destroy!

    redirect_to profile_custom_emoji_index_path
  end

  private

  def namespace
    @namespace ||= current_user.namespace
  end

  def custom_emoji_params
    params.require(:custom_emoji).permit(:name, :file, :namespace_id)
  end
end
