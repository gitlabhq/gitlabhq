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

        def pretext
          "I created an issue on #{author_profile_link}'s behalf: *#{issue_link}* in #{project_link}"
        end

        def issue_link
          "[#{issue.to_reference}](#{project_issue_url(issue.project, issue)})"
        end

        def response_message(custom_pretext: pretext)
          {
            text: pretext
          }
        end
      end
    end
  end
end
