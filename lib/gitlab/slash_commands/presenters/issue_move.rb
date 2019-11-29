# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueMove < Presenters::Base
        include Presenters::IssueBase

        def present(old_issue)
          in_channel_response(moved_issue(old_issue))
        end

        def display_move_error(error)
          message = header_with_list("The action was not successful, because:", [error])

          ephemeral_response(text: message)
        end

        private

        def moved_issue(old_issue)
          response_message(custom_pretext: custom_pretext(old_issue))
        end

        def fallback_message
          "Issue #{issue.to_reference}: #{issue.title}"
        end

        def custom_pretext(old_issue)
          "Moved issue *#{issue_link(old_issue)}* to *#{issue_link(issue)}*"
        end

        def issue_link(issue)
          "[#{issue.to_reference}](#{project_issue_url(issue.project, issue)})"
        end
      end
    end
  end
end
