require 'action_controller'
require 'gitlab/markdown'
require 'gitlab_emoji'
require 'html/pipeline/filter'

module Gitlab
  module Markdown
    # HTML filter that replaces :emoji: with images.
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
          next unless content.include?(':')
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          html = emoji_image_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      # Replace :emoji: with corresponding images.
      #
      # text - String text to replace :emoji: in.
      #
      # Returns a String with :emoji: replaced with images.
      def emoji_image_filter(text)
        text.gsub(emoji_pattern) do |match|
          name = $1
          "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{emoji_url(name)}' height='20' width='20' align='absmiddle' />"
        end
      end

      private

      def emoji_url(name)
        emoji_path = "emoji/#{emoji_filename(name)}"
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

      def url_to_image(image)
        ActionController::Base.helpers.url_to_image(image)
      end

      # Build a regexp that matches all valid :emoji: names.
      def self.emoji_pattern
        @emoji_pattern ||= /:(#{Emoji.emojis_names.map { |name| Regexp.escape(name) }.join('|')}):/
      end

      def emoji_pattern
        self.class.emoji_pattern
      end

      def emoji_filename(name)
        "#{Emoji.emoji_filename(name)}.png"
      end
    end
  end
end
