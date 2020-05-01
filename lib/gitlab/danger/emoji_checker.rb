# frozen_string_literal: true

require_relative '../json'

module Gitlab
  module Danger
    class EmojiChecker
      DIGESTS = File.expand_path('../../../fixtures/emojis/digests.json', __dir__)
      ALIASES = File.expand_path('../../../fixtures/emojis/aliases.json', __dir__)

      # A regex that indicates a piece of text _might_ include an Emoji. The regex
      # alone is not enough, as we'd match `:foo:bar:baz`. Instead, we use this
      # regex to save us from having to check for all possible emoji names when we
      # know one definitely is not included.
      LIKELY_EMOJI = /:[\+a-z0-9_\-]+:/.freeze

      UNICODE_EMOJI_REGEX = %r{(
        [\u{1F300}-\u{1F5FF}] |
        [\u{1F1E6}-\u{1F1FF}] |
        [\u{2700}-\u{27BF}] |
        [\u{1F900}-\u{1F9FF}] |
        [\u{1F600}-\u{1F64F}] |
        [\u{1F680}-\u{1F6FF}] |
        [\u{2600}-\u{26FF}]
      )}x.freeze

      def initialize
        names = Gitlab::Json.parse(File.read(DIGESTS)).keys +
          Gitlab::Json.parse(File.read(ALIASES)).keys

        @emoji = names.map { |name| ":#{name}:" }
      end

      def includes_text_emoji?(text)
        return false unless text.match?(LIKELY_EMOJI)

        @emoji.any? { |emoji| text.include?(emoji) }
      end

      def includes_unicode_emoji?(text)
        text.match?(UNICODE_EMOJI_REGEX)
      end
    end
  end
end
