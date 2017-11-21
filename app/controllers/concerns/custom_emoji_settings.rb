module CustomEmojiSettings
  extend ActiveSupport::Concern

  included do
    before_action :set_custom_emoji
  end

  def index
  end

  def create
    @new_custom_emoji = namespace.custom_emoji.new(custom_emoji_params)

    if @new_custom_emoji.save
      redirect_to custom_emoji_index_path
    else
      render :index
    end
  end

  def destroy
    namespace.custom_emoji.find_by(id: params[:id])&.destroy!

    redirect_to custom_emoji_index_path, status: 302
  end

  private

  def set_custom_emoji
    @custom_emoji = namespace.custom_emoji.all
    @new_custom_emoji ||= namespace.custom_emoji.new
  end

  def custom_emoji_params
    params.require(:custom_emoji).permit(:name, :file, :group_id)
  end

  def namespace
    raise NotImplementedError
  end

  def custom_emoji_index_path
    raise NotImplementedError
  end
end
