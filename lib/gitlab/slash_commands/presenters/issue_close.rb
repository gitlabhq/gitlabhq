# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueClose < Presenters::Base
        include Presenters::IssueBase

        def present
          if resource.confidential?
            ephemeral_response(response_message)
          else
            in_channel_response(response_message)
          end
        end

        def already_closed
          ephemeral_response(text: "Issue #{resource.to_reference} is already closed.")
        end

        private

        def fallback_message
          "Closed issue #{issue.to_reference}: #{issue.title}"
        end

        def pretext
          "I closed an issue on #{author_profile_link}'s behalf: *#{issue.to_reference}* in #{project_link}"
        end
      end
    end
  end
end
