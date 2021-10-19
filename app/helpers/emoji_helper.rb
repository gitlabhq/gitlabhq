# frozen_string_literal: true

module EmojiHelper
  def emoji_icon(emoji_name, *options)
    emoji = TanukiEmoji.find_by_alpha_code(emoji_name)
    raw Gitlab::Emoji.gl_emoji_tag(emoji, *options)
  end
end
