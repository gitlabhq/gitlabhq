module Gitlab::ChatCommands::Presenters
  class NewIssue < Gitlab::ChatCommands::Presenters::Issuable
    def present
      if @resource.errors.any?
        display_errors
      else
        in_channel_response(new_issue)
      end
    end

    def new_issue
      {
        attachments: [
          {
            title:        @resource.title,
            title_link:   resource_url,
            author_name:  author.name,
            author_icon:  author.avatar_url,
            fallback:     "Issue created: #{@resource.title}",
            pretext:      pretext,
            mrkdwn_in: [
              :title,
              :pretext
            ]
          }
        ]
      }
    end

    def pretext
      profile_link = "[#{author.to_reference}](#{user_url(author)})"
      project_link = "[#{project.to_reference}](#{project.web_url})"

      "New issue by #{profile_link} on #{project_link}"
    end
  end
end
