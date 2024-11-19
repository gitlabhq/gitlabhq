# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/emoji.js
module Banzai
  module Filter
    # HTML filter that replaces :emoji: and unicode with images.
    #
    # Based on HTML::Pipeline::EmojiFilter
    class EmojiFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck

      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set
      IGNORE_UNICODE_EMOJIS = %w[™ © ®].freeze

      def call
        @emoji_count = 0

        doc.xpath('descendant-or-self::text()[not(ancestor::a[@data-footnote-backref])]').each do |node|
          break if Banzai::Filter.filter_item_limit_exceeded?(@emoji_count)
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          content = node.to_html

          html = emoji_unicode_element_unicode_filter(content)
          html = emoji_name_element_unicode_filter(html) if content.include?(':')

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
        Gitlab::Utils::Gsub
          .gsub_with_limit(text, emoji_pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
          emoji = TanukiEmoji.find_by_alpha_code(match_data[0])

          process_emoji_tag(emoji, match_data[0])
        end
      end

      # Replace unicode emoji with corresponding gl-emoji unicode.
      #
      # text - String text to replace unicode emoji in.
      #
      # Returns a String with unicode emoji replaced with gl-emoji unicode.
      def emoji_unicode_element_unicode_filter(text)
        Gitlab::Utils::Gsub
          .gsub_with_limit(text, emoji_unicode_pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
          if ignore_emoji?(match_data[0])
            match_data[0]
          else
            emoji = TanukiEmoji.find_by_codepoints(match_data[0])

            process_emoji_tag(emoji, match_data[0])
          end
        end
      end

      def process_emoji_tag(emoji, fallback)
        return fallback unless emoji

        @emoji_count += 1
        Gitlab::Emoji.gl_emoji_tag(emoji)
      end

      def ignore_emoji?(text)
        IGNORE_UNICODE_EMOJIS.include?(text)
      end

      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||= TanukiEmoji.index.alpha_code_pattern
      end

      def self.emoji_unicode_pattern
        # Use regex from unicode-emoji gem. This is faster than the built-in TanukiEmoji
        # regex for large documents.
        Unicode::Emoji::REGEX_VALID_INCLUDE_TEXT
      end

      private

      def emoji_pattern
        self.class.emoji_pattern
      end

      def emoji_unicode_pattern
        self.class.emoji_unicode_pattern
      end
    end
  end
end
