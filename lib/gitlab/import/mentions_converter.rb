# frozen_string_literal: true

module Gitlab
  module Import
    class MentionsConverter
      include UserFromMention

      # Captures anything in brackets after an @ but does not capture the @. It allows mentions
      # like @{1111:11-11} to be captured even though it doesn't match User.reference_pattern
      BITBUCKET_MENTIONS_REGEX = /(?<=@)(\{.+?\})/
      GITLAB_MENTIONS_REGEX = User.reference_pattern
      MENTION_PLACEHOLDER = '~GITLAB_MENTION_PLACEHOLDER~'

      attr_reader :importer, :project_id, :project_creator

      def initialize(importer, project)
        @importer = importer
        @project_id = project.id
        @project_creator = project.creator
      end

      def convert(text)
        replace_mentions(text.dup)
      end

      private

      def replace_mentions(text)
        mentions = pluck_mentions_from_text(text)
        altered_mentions = []

        mentions.each do |mention|
          user = user_from_cache(mention)
          replacement_mention =
            if user.is_a?(User)
              "#{MENTION_PLACEHOLDER}#{user.username}"
            elsif user
              "`#{MENTION_PLACEHOLDER}#{user}`"
            else
              "`#{MENTION_PLACEHOLDER}#{mention}`"
            end

          altered_mentions << [mention, replacement_mention]
        end

        altered_mentions.each do |original_mention, altered_mention|
          text.sub!("@#{original_mention}", altered_mention)
        end

        text.gsub(MENTION_PLACEHOLDER, '@')
      end

      def pluck_mentions_from_text(text)
        mentions = text.scan(GITLAB_MENTIONS_REGEX) + text.scan(BITBUCKET_MENTIONS_REGEX)
        mentions.flatten
      end
    end
  end
end
