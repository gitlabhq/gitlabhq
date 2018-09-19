# frozen_string_literal: true

module EmojiHelper
  def emoji_icon(*args)
    raw Gitlab::Emoji.gl_emoji_tag(*args)
  end
end
