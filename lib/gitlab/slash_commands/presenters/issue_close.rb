# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueClose < Presenters::Base
        include Presenters::IssueBase

        def present
          if @resource.confidential?
            ephemeral_response(close_issue)
          else
            in_channel_response(close_issue)
          end
        end

        def already_closed
          ephemeral_response(text: "Issue #{@resource.to_reference} is already closed.")
        end

        private

        def close_issue
          {
            attachments: [
              {
                title:        "#{@resource.title} · #{@resource.to_reference}",
                title_link:   resource_url,
                author_name:  author.name,
                author_icon:  author.avatar_url,
                fallback:     "Closed issue #{@resource.to_reference}: #{@resource.title}",
                pretext:      pretext,
                color:        color(@resource),
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
          "I closed an issue on #{author_profile_link}'s behalf: *#{@resource.to_reference}* in #{project_link}"
        end
      end
    end
  end
end
