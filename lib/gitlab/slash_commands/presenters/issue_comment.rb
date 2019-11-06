# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueComment < Presenters::Base
        include Presenters::NoteBase

        def present
          ephemeral_response(new_note)
        end

        private

        def new_note
          {
            attachments: [
              {
                title:        "#{issue.title} · #{issue.to_reference}",
                title_link:   resource_url,
                author_name:  author.name,
                author_icon:  author.avatar_url,
                fallback:     "New comment on #{issue.to_reference}: #{issue.title}",
                pretext:      pretext,
                color:        color,
                fields:       fields,
                mrkdwn_in: [
                  :title,
                  :pretext,
                  :fields
                ]
              }
            ]
          }
        end

        def pretext
          "I commented on an issue on #{author_profile_link}'s behalf: *#{issue.to_reference}* in #{project_link}"
        end
      end
    end
  end
end
