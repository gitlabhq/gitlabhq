# frozen_string_literal: true

module Banzai
  module Filter
    class CustomEmojiFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck
      include Gitlab::Utils::StrongMemoize

      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      def call
        return doc unless resource_parent

        doc.xpath('descendant-or-self::text()').each do |node|
          content = node.to_html

          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)
          next unless content.include?(':')
          next unless has_custom_emoji?

          html = custom_emoji_name_element_filter(content)

          node.replace(html) unless html == content
        end

        doc
      end

      def custom_emoji_pattern
        @emoji_pattern ||=
          /(?<=[^[:alnum:]:]|\n|^)
          :(#{CustomEmoji::NAME_REGEXP}):
          (?=[^[:alnum:]:]|$)/xo
      end

      def custom_emoji_name_element_filter(text)
        Gitlab::Utils::Gsub
          .gsub_with_limit(text, custom_emoji_pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
          name = match_data[1]
          custom_emoji = all_custom_emoji[name]

          if custom_emoji
            Gitlab::Emoji.custom_emoji_tag(custom_emoji.name, custom_emoji.url)
          else
            match_data[0]
          end
        end
      end

      private

      def has_custom_emoji?
        all_custom_emoji&.any?
      end
      strong_memoize_attr :has_custom_emoji?

      def resource_parent
        context[:project] || context[:group]
      end

      def custom_emoji_candidates
        doc.to_html.scan(/:(#{CustomEmoji::NAME_REGEXP}):/o).flatten.uniq
      end

      def all_custom_emoji
        Groups::CustomEmojiFinder.new(resource_parent, { include_ancestor_groups: true })
          .execute
          .by_name(custom_emoji_candidates)
          .index_by(&:name)
      end
      strong_memoize_attr :all_custom_emoji
    end
  end
end
