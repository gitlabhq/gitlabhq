module Gitlab::ChatCommands::Presenters
  class ShowIssue < Gitlab::ChatCommands::Presenters::Issuable
    def present
      in_channel_response(show_issue)
    end

    private

    def show_issue
      {
        attachments: [
          {
            title:        @resource.title,
            title_link:   resource_url,
            author_name:  author.name,
            author_icon:  author.avatar_url,
            fallback:     "#{@resource.to_reference}: #{@resource.title}",
            text:         text,
            fields:       fields,
            mrkdwn_in: [
              :title,
              :text
            ]
          }
        ]
      }
    end

    def text
      message = ""
      message << ":+1: #{@resource.upvotes} " unless @resource.upvotes.zero?
      message << ":-1: #{@resource.downvotes} " unless @resource.downvotes.zero?
      message << ":speech_balloon: #{@resource.user_notes_count}" unless @resource.user_notes_count.zero?

      message
    end
  end
end
