module Banzai
  module Filter
    # HTML filter that replaces :emoji: and unicode with images.
    #
    # Based on HTML::Pipeline::EmojiFilter
    #
    # Context options:
    #   :asset_root
    #   :asset_host
    class EmojiFilter < HTML::Pipeline::Filter
      IGNORED_ANCESTOR_TAGS = %w(pre code tt).to_set

      def call
        search_text_nodes(doc).each do |node|
          content = node.to_html
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)
          if content.include?(':') || node.text.match(emoji_unicode_pattern)
            html = emoji_name_image_filter(content)
            html = emoji_unicode_image_filter(html)
            next if html == content
            node.replace(html)
          end

        end

        doc
      end

      # Replace :emoji: with corresponding images.
      #
      # text - String text to replace :emoji: in.
      #
      # Returns a String with :emoji: replaced with images.
      def emoji_name_image_filter(text)
        text.gsub(emoji_pattern) do |match|
          name = $1
          "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{emoji_url(name)}' height='20' width='20' align='absmiddle' />"
        end
      end


      # Replace unicode emojis with corresponding images if they exist.
      #
      # text - String text to replace unicode emojis in.
      #
      # Returns a String with unicode emojis replaced with images.

      def emoji_unicode_image_filter(text)
        text.gsub(emoji_unicode_pattern) do |moji|
          "<img class='emoji' title=':#{Gitlab::Emoji.emojis_by_moji[moji]['name']}:' alt=':#{Gitlab::Emoji.emojis_by_moji[moji]['name']}:' src='#{emoji_unicode_url(moji)}' height='20' width='20' align='absmiddle' />"
        end
      end
      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||= /:(#{Gitlab::Emoji.emojis_names.map { |name| Regexp.escape(name) }.join('|')}):/
      end
      # Build a regexp that matches all valid unicode emojis names.
      def self.emoji_unicode_pattern
        @emoji_unicode_pattern ||= /(#{Gitlab::Emoji.emojis_unicodes.map { |moji| Regexp.escape(moji) }.join('|')})/

      end
      private

      def emoji_url(name)
        emoji_path = emoji_filename(name)

        if context[:asset_host]
          # Asset host is specified.
          url_to_image(emoji_path)
        elsif context[:asset_root]
          # Gitlab url is specified
          File.join(context[:asset_root], url_to_image(emoji_path))
        else
          # All other cases
          url_to_image(emoji_path)
        end
      end

      def emoji_unicode_url(moji)
        emoji_unicode_path = emoji_unicode_filename(moji)

        if context[:asset_host]
          # Asset host is specified.
          url_to_image(emoji_unicode_path)
        elsif context[:asset_root]
          # Gitlab url is specified
          File.join(context[:asset_root], url_to_image(emoji_unicode_path))
        else
          # All other cases
          url_to_image(emoji_unicode_path)
        end
      end

      def url_to_image(image)
        ActionController::Base.helpers.url_to_image(image)
      end

      def emoji_pattern
        self.class.emoji_pattern
      end

      def emoji_filename(name)
        "#{Gitlab::Emoji.emoji_filename(name)}.png"
      end
      def emoji_unicode_pattern
        self.class.emoji_unicode_pattern
      end

      def emoji_unicode_filename(name)
        "#{Gitlab::Emoji.emoji_unicode_filename(name)}.png"
      end
    end
  end
end
