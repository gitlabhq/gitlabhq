# frozen_string_literal: true

module Gitlab
  module Import
    module UsernameMentionRewriter
      # Updates @username mentions in description and note
      # text fields, wrapping them in backticks, so that they appear as
      # code-formatted text in the UI.
      # Handles trailing punctuation. Handles usernames containing -, _, /, or . characters
      # Handles already code-formatted text blocks, e.g. "```Some example @text```"
      # or "`Some example @text`" remain unchanged.
      # Handles @ instances in email addresses or urls
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/477097

      MENTION_REGEX = Gitlab::UntrustedRegexp.new('(`+[^`]*`+)|((?:^|\s|\()@[\w\-#./]+)')

      def update_username_mentions(relation_hash)
        if relation_hash['description']
          relation_hash['description'] = wrap_mentions_in_backticks(relation_hash['description'])
        end

        relation_hash['note'] = wrap_mentions_in_backticks(relation_hash['note']) if relation_hash['note']
      end

      def wrap_mentions_in_backticks(text)
        return text unless text.present?

        if MENTION_REGEX.match?(text)
          text = MENTION_REGEX.replace_gsub(text) do |match|
            case match[0]
            when /^`/
              match[0]
            when /^ /
              " `#{match[0].lstrip}`"
            when /^\(/
              "(`#{match[0].sub(/^./, '')}`"
            else
              "`#{match[0]}`"
            end
          end
        end

        text
      end
    end
  end
end
