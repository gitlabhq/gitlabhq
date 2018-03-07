module Gitlab
  module SlashCommands
    module Presenters
      class IssueShow < Presenters::Base
        include Presenters::IssueBase

        def present
          if @resource.confidential?
            ephemeral_response(show_issue)
          else
            in_channel_response(show_issue)
          end
        end

        private

        def show_issue
          {
            attachments: [
              {
                title:        "#{@resource.title} · #{@resource.to_reference}",
                title_link:   resource_url,
                author_name:  author.name,
                author_icon:  author.avatar_url,
                fallback:     "Issue #{@resource.to_reference}: #{@resource.title}",
                pretext:      pretext,
                text:         text,
                color:        color(@resource),
                fields:       fields,
                mrkdwn_in: [
                  :pretext,
                  :text,
                  :fields
                ]
              }
            ]
          }
        end

        def text
          message = "**#{status_text(@resource)}**"

          if @resource.upvotes.zero? && @resource.downvotes.zero? && @resource.user_notes_count.zero?
            return message
          end

          message << " · "
          message << ":+1: #{@resource.upvotes} " unless @resource.upvotes.zero?
          message << ":-1: #{@resource.downvotes} " unless @resource.downvotes.zero?
          message << ":speech_balloon: #{@resource.user_notes_count}" unless @resource.user_notes_count.zero?

          message
        end

        def pretext
          "Issue *#{@resource.to_reference}* from #{project.full_name}"
        end
      end
    end
  end
end
