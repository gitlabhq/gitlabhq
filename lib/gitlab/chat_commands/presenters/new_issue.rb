module Gitlab
  module ChatCommands
    module Presenters
      class NewIssue < Presenters::Issuable
        def present
          in_channel_response(show_issue)
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
                fallback:     "New issue #{@resource.to_reference}: #{@resource.title}",
                pretext:      pretext,
                color:        color(@resource),
                fields:       fields,
                mrkdwn_in: [
                  :title,
                  :text
                ]
              }
            ]
          }
        end

        def pretext
          "I opened an issue on behalf on #{author_profile_link}: *#{@resource.to_reference}* from #{project.name_with_namespace}"
        end

        def author_profile_link
          "[#{author.to_reference}](#{url_for(author)})"
        end
      end
    end
  end
end
