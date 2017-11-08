module Banzai
  module Filter
    # Context options:
    #   :project (required) - Current project, ignored if reference is cross-project.
    class CustomEmojiFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::AssetTagHelper

      IGNORED_ANCESTOR_TAGS = %w(pre code tt).to_set

      def call
        return doc unless project

        search_text_nodes(doc).each do |node|
          content = node.to_html

          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)
          next unless content.include?(':') || node.text.match(custom_emoji_pattern)

          html = custom_emoji_name_element_filter(content)

          node.replace(html) unless html == content
        end

        doc
      end

      # Build a regexp that matches all valid :emoji: names.
      def custom_emoji_pattern
        @emoji_pattern ||=
          /(?<=[^[:alnum:]:]|\n|^)
          :(#{custom_emoji_to_regex}):
          (?=[^[:alnum:]:]|$)/x
      end

      def custom_emoji_name_element_filter(text)
        text.gsub(custom_emoji_pattern) do |match|
          name = $1
          Gitlab::Emoji.gl_custom_emoji_tag(name, all_custom_emoji[name])
        end
      end

      private

      def project
        context[:project]
      end

      def custom_emoji_candidates
        doc.to_html.scan(/:\w+:/).map { |p_emoji| p_emoji.gsub(':', '') }
      end

      def all_custom_emoji
        @all_custom_emoji ||= project.namespace.custom_emoji_url_by_name(custom_emoji_candidates)
      end

      def custom_emoji_to_regex
        all_custom_emoji.keys.map { |name| Regexp.escape(name) }.join('|')
      end
    end
  end
end
