# frozen_string_literal: true

module Gitlab
  module Import
    class MentionsConverter
      include UserFromMention

      MENTIONS_REGEX = User.reference_pattern
      MENTION_PLACEHOLDER = '~GITLAB_MENTION_PLACEHOLDER~'

      attr_reader :importer, :project_id

      def initialize(importer, project_id)
        @importer = importer
        @project_id = project_id
      end

      def convert(text)
        replace_mentions(text.dup)
      end

      private

      def replace_mentions(text)
        mentions = text.scan(MENTIONS_REGEX).flatten
        altered_mentions = []

        mentions.each do |mention|
          user = user_from_cache(mention)

          if user
            altered_mentions << ["@#{mention}", "#{MENTION_PLACEHOLDER}#{user.username}"]
            next
          end

          altered_mentions << ["@#{mention}", "`#{MENTION_PLACEHOLDER}#{mention}`"]
        end

        altered_mentions.each do |original_mention, altered_mention|
          text.sub!(original_mention, altered_mention)
        end

        text.gsub(MENTION_PLACEHOLDER, '@')
      end
    end
  end
end
