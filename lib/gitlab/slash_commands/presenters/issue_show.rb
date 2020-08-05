# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class IssueShow < Presenters::Base
        include Presenters::IssueBase

        def present
          if resource.confidential?
            ephemeral_response(response_message)
          else
            in_channel_response(response_message)
          end
        end

        private

        def fallback_message
          "Issue #{resource.to_reference}: #{resource.title}"
        end

        def text
          message = ["**#{status_text(resource)}**"]

          if resource.upvotes == 0 && resource.downvotes == 0 && resource.user_notes_count == 0
            return message.join
          end

          message << " · "
          message << ":+1: #{resource.upvotes} " unless resource.upvotes == 0
          message << ":-1: #{resource.downvotes} " unless resource.downvotes == 0
          message << ":speech_balloon: #{resource.user_notes_count}" unless resource.user_notes_count == 0

          message.join
        end

        def pretext
          "Issue *#{resource.to_reference}* from #{project.full_name}"
        end
      end
    end
  end
end
