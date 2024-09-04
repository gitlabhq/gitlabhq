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
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/477097

      MENTION_REGEX = Gitlab::UntrustedRegexp.new('(`+[^`]*`+)|(@[\w\-#./]+)')

      def update_username_mentions(relation_hash)
        relation_hash['description'] = update_text(relation_hash['description']) if relation_hash['description']

        relation_hash['note'] = update_text(relation_hash['note']) if relation_hash['note']
      end

      def update_text(text)
        return text unless text.present?

        if MENTION_REGEX.match?(text)
          text = MENTION_REGEX.replace_gsub(text) do |match|
            if match[0].start_with?('`')
              match[0]
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
