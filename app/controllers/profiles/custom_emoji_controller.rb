class Profiles::CustomEmojiController < Profiles::ApplicationController
  include CustomEmojiSettings

  private

  def namespace
    current_user.namespace
  end

  def custom_emoji_index_path
    profile_custom_emoji_index_path
  end
end
