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

      def call
        @emoji_count = 0

        doc.xpath('descendant-or-self::text()').each do |node|
          break if Banzai::Filter.filter_item_limit_exceeded?(@emoji_count)
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          content = node.to_html

          next unless content.include?(':') || emoji_unicode_pattern_untrusted.match?(content)

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
        Gitlab::Utils::Gsub
          .gsub_with_limit(text, emoji_pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
          emoji = TanukiEmoji.find_by_alpha_code(match_data[0])
          @emoji_count += 1 if emoji

          Gitlab::Emoji.gl_emoji_tag(emoji) if emoji
        end
      end

      # Replace unicode emoji with corresponding gl-emoji unicode.
      #
      # text - String text to replace unicode emoji in.
      #
      # Returns a String with unicode emoji replaced with gl-emoji unicode.
      def emoji_unicode_element_unicode_filter(text)
        emoji_unicode_pattern_untrusted.replace_gsub(text, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
          emoji = TanukiEmoji.find_by_codepoints(match[1])
          @emoji_count += 1 if emoji

          Gitlab::Emoji.gl_emoji_tag(emoji) if emoji
        end
      end

      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||= TanukiEmoji.index.alpha_code_pattern
      end

      # Build an unstrusted regexp that matches all valid unicode emojis names.
      def self.emoji_unicode_pattern_untrusted
        return @emoji_unicode_pattern_untrusted if @emoji_unicode_pattern_untrusted

        source = TanukiEmoji.index.codepoints_pattern.source
        @emoji_unicode_pattern_untrusted = Gitlab::UntrustedRegexp.new(source)
      end

      private

      def emoji_pattern
        self.class.emoji_pattern
      end

      def emoji_unicode_pattern_untrusted
        self.class.emoji_unicode_pattern_untrusted
      end
    end
  end
end
