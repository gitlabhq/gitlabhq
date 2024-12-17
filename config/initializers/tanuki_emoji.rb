# frozen_string_literal: true

# Pre-load the emoji index so it doesn't happen during the
# first run of EmojiFilter.
TanukiEmoji.index
