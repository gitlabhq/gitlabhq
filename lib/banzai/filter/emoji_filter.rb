# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/emoji.js
module Banzai
  module Filter
    # HTML filter that replaces :emoji: and unicode with images.
    #
    # Based on HTML::Pipeline::EmojiFilter
    class EmojiFilter < HTML::Pipeline::Filter
      IGNORED_ANCESTOR_TAGS = %w(pre code tt).to_set
      IGNORE_UNICODE_EMOJIS = %w(™ © ®).freeze

      def call
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
        text.gsub(emoji_pattern) do |match|
          name = Regexp.last_match(1)
          Gitlab::Emoji.gl_emoji_tag(name)
        end
      end

      # Replace unicode emoji with corresponding gl-emoji unicode.
      #
      # text - String text to replace unicode emoji in.
      #
      # Returns a String with unicode emoji replaced with gl-emoji unicode.
      def emoji_unicode_element_unicode_filter(text)
        text.gsub(emoji_unicode_pattern) do |moji|
          emoji_info = Gitlab::Emoji.emojis_by_moji[moji]
          Gitlab::Emoji.gl_emoji_tag(emoji_info['name'])
        end
      end

      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||=
          %r{(?<=[^[:alnum:]:]|\n|^)
          :(#{Gitlab::Emoji.emojis_names.map { |name| Regexp.escape(name) }.join('|')}):
          (?=[^[:alnum:]:]|$)}x
      end

      # Build a regexp that matches all valid unicode emojis names.
      def self.emoji_unicode_pattern
        @emoji_unicode_pattern ||=
          begin
            filtered_emojis = Gitlab::Emoji.emojis_unicodes - IGNORE_UNICODE_EMOJIS
            /(#{filtered_emojis.map { |moji| Regexp.escape(moji) }.join('|')})/
          end
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
