# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueNew < Presenters::Base
        include Presenters::IssueBase

        def present
          in_channel_response(response_message)
        end

        private

        def fallback_message
          "New issue #{issue.to_reference}: #{issue.title}"
        end

        def fields_with_markdown
          %i(title pretext text fields)
        end

        def pretext
          "I created an issue on #{author_profile_link}'s behalf: *#{issue.to_reference}* in #{project_link}"
        end
      end
    end
  end
end
