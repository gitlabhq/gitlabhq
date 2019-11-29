# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueComment < Presenters::Base
        include Presenters::NoteBase

        def present
          ephemeral_response(response_message)
        end

        private

        def fallback_message
          "New comment on #{issue.to_reference}: #{issue.title}"
        end

        def pretext
          "I commented on an issue on #{author_profile_link}'s behalf: *#{issue.to_reference}* in #{project_link}"
        end
      end
    end
  end
end
