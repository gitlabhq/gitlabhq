# coding: utf-8
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
          {
            attachments: [
              {
                title:        "#{@resource.title} · #{@resource.to_reference}",
                title_link:   resource_url,
                author_name:  author.name,
                author_icon:  author.avatar_url,
                fallback:     "Issue #{@resource.to_reference}: #{@resource.title}",
                pretext:      pretext(old_issue),
                color:        color(@resource),
                fields:       fields,
                mrkdwn_in: [
                  :title,
                  :pretext,
                  :text,
                  :fields
                ]
              }
            ]
          }
        end

        def pretext(old_issue)
          "Moved issue *#{issue_link(old_issue)}* to *#{issue_link(@resource)}*"
        end

        def issue_link(issue)
          "[#{issue.to_reference}](#{project_issue_url(issue.project, issue)})"
        end
      end
    end
  end
end
