module Gitlab
  module SlashCommands
    module Presenters
      class IssueNew < Presenters::Base
        include Presenters::IssueBase

        def present
          in_channel_response(new_issue)
        end

        private

        def new_issue
          {
            attachments: [
              {
                title:        "#{@resource.title} · #{@resource.to_reference}",
                title_link:   resource_url,
                author_name:  author.name,
                author_icon:  author.avatar_url,
                fallback:     "New issue #{@resource.to_reference}: #{@resource.title}",
                pretext:      pretext,
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

        def pretext
          "I created an issue on #{author_profile_link}'s behalf: **#{@resource.to_reference}** in #{project_link}"
        end

        def project_link
          "[#{project.full_name}](#{project.web_url})"
        end

        def author_profile_link
          "[#{author.to_reference}](#{url_for(author)})"
        end
      end
    end
  end
end
