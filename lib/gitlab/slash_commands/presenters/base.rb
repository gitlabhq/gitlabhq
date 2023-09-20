# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Base
        include Gitlab::Routing

        def initialize(resource = nil)
          @resource = resource
        end

        def display_errors
          message = header_with_list("The action was not successful, because:", @resource.errors.full_messages)

          ephemeral_response(text: message)
        end

        private

        attr_reader :resource

        def header_with_list(header, items)
          message = [header]

          items.each do |item|
            message << "- #{item}"
          end

          message.join("\n")
        end

        def ephemeral_response(message)
          response = {
            response_type: :ephemeral,
            status: 200
          }.merge(message)

          format_response(response)
        end

        def in_channel_response(message)
          response = {
            response_type: :in_channel,
            status: 200
          }.merge(message)

          format_response(response)
        end

        def format_response(response)
          response[:text] = format(response[:text]) if response.key?(:text)

          if response.key?(:attachments)
            response[:attachments].each do |attachment|
              attachment[:pretext] = format(attachment[:pretext]) if attachment[:pretext]
              attachment[:text] = format(attachment[:text]) if attachment[:text]
            end
          end

          response
        end

        # Convert Markdown to slacks format
        def format(string)
          ::Slack::Messenger::Util::LinkFormatter.format(string)
        end

        def resource_url
          url_for(
            [
              resource.project,
              resource
            ]
          )
        end

        def project_link
          "[#{project.full_name}](#{project.web_url})"
        end

        def author_profile_link
          "[#{author.to_reference}](#{url_for(author)})"
        end

        def response_message(custom_pretext: pretext)
          {
            attachments: [
              {
                title: "#{issue.title} · #{issue.to_reference}",
                title_link: resource_url,
                author_name: author.name,
                author_icon: author.avatar_url(only_path: false),
                fallback: fallback_message,
                pretext: custom_pretext,
                text: text,
                color: color(resource),
                fields: fields,
                mrkdwn_in: fields_with_markdown
              }
            ]
          }
        end

        def pretext
          ''
        end

        def text
          ''
        end

        def fields_with_markdown
          %i[title pretext fields]
        end
      end
    end
  end
end
