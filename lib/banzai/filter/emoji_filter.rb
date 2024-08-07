# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/emoji.js
module Banzai
  module Filter
    # HTML filter that replaces :emoji: and unicode with images.
    #
    # Based on HTML::Pipeline::EmojiFilter
    class EmojiFilter < HTML::Pipeline::Filter
      include Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck

      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      # Limit of how many emojis we will process.
      # Protects against pathological number of emojis.
      # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/434803
      EMOJI_LIMIT = 1000

      def call_with_timeout
        @emoji_count = 0

        doc.xpath('descendant-or-self::text()').each do |node|
          content = node.to_html
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          next unless content.include?(':') || node.text.match(emoji_unicode_pattern)

          html = emoji_unicode_element_unicode_filter(content)
          html = emoji_name_element_unicode_filter(html)

          next if html == content

          node.replace(html)
        end

        doc
      end

      # Replace :emoji: with corresponding gl-emoji unicode.
      #
      # text - String text to replace :emoji: in.
      #
      # Returns a String with :emoji: replaced with gl-emoji unicode.
      def emoji_name_element_unicode_filter(text)
        scan_and_replace(text, emoji_pattern) do |matched_text|
          TanukiEmoji.find_by_alpha_code(matched_text)
        end
      end

      # Replace unicode emoji with corresponding gl-emoji unicode.
      #
      # text - String text to replace unicode emoji in.
      #
      # Returns a String with unicode emoji replaced with gl-emoji unicode.
      def emoji_unicode_element_unicode_filter(text)
        scan_and_replace(text, emoji_unicode_pattern) do |matched_text|
          TanukiEmoji.find_by_codepoints(matched_text)
        end
      end

      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||= TanukiEmoji.index.alpha_code_pattern
      end

      # Build a regexp that matches all valid unicode emojis names.
      def self.emoji_unicode_pattern
        @emoji_unicode_pattern ||= TanukiEmoji.index.codepoints_pattern
      end

      private

      # This performs the same function as a `gsub`. However this version
      # allows us to break out of the replacement loop when the limit is
      # reached. Benchmarking showed performance was roughly equivalent.
      def scan_and_replace(text, pattern)
        scanner = StringScanner.new(text)
        buffer = +''

        return text unless scanner.exist?(pattern)

        until scanner.eos?
          portion = scanner.scan_until(pattern)

          if portion.nil?
            buffer << scanner.rest
            scanner.terminate
            break
          end

          if emoji_limit_reached?(@emoji_count)
            buffer << portion
            buffer << scanner.rest
            scanner.terminate
            break
          end

          emoji = yield(scanner.matched)
          @emoji_count += 1 if emoji
          buffer << portion.sub(scanner.matched, Gitlab::Emoji.gl_emoji_tag(emoji))
        end

        buffer
      end

      def emoji_pattern
        self.class.emoji_pattern
      end

      def emoji_unicode_pattern
        self.class.emoji_unicode_pattern
      end

      def emoji_limit_reached?(count)
        count >= EMOJI_LIMIT
      end
    end
  end
end
