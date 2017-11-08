module EmojiHelper
  def emoji_icon(*args)
    raw Gitlab::Emoji.gl_emoji_tag(*args)
  end

  def custom_emoji_icon(*args)
    raw Gitlab::Emoji.gl_custom_emoji_tag(*args)
  end
end
