# frozen_string_literal: true

module Gitlab
  module Chat
    module Responder
      class Mattermost < Responder::Base
        SUCCESS_COLOR = '#00c100'
        FAILURE_COLOR = '#e40303'

        # Slack breaks messages apart if they're around 4 KB in size. We use a
        # slightly smaller limit here to account for user mentions.
        MESSAGE_SIZE_LIMIT = 3.5.kilobytes

        # Sends a response back to Mattermost
        #
        # body - The message payload to send back to Mattermost, as a Hash.
        def send_response(body)
          Gitlab::HTTP.post(
            pipeline.chat_data.response_url,
            {
              headers: { 'Content-Type': 'application/json' },
              body: body.to_json
            }
          )
        end

        # Sends the output for a build that completed successfully.
        #
        # output - The output produced by the chat command.
        def success(output)
          return if output.empty?

          send_response(
            response_type: :in_channel,
            attachments: [
              {
                color: SUCCESS_COLOR,
                text: "ChatOps job started by #{user_ref} completed successfully",
                fields: [
                  {
                    short: true,
                    title: "ID",
                    value: build_ref.to_s
                  },
                  {
                    short: true,
                    title: "Name",
                    value: build.name
                  },
                  {
                    short: false,
                    title: "Output",
                    value: success_message(output)
                  }
                ]
              }
            ]
          )
        end

        # Sends the output for a build that failed.
        def failure
          send_response(
            response_type: :in_channel,
            attachments: [
              {
                color: FAILURE_COLOR,
                text: "ChatOps job started by #{user_ref} failed!",
                fields: [
                  {
                    short: true,
                    title: "ID",
                    value: build_ref.to_s
                  },
                  {
                    short: true,
                    title: "Name",
                    value: build.name
                  }
                ]
              }
            ]
          )
        end

        # Returns the output to send back after a command has been scheduled.
        def scheduled_output
          {
            response_type: :ephemeral,
            text: "Your ChatOps job #{build_ref} has been created!"
          }
        end

        private

        def success_message(output)
          <<~HEREDOC.chomp
            ```shell
            #{strip_ansi_colorcodes(limit_output(output))}
            ```
          HEREDOC
        end

        def limit_output(output)
          if output.bytesize <= MESSAGE_SIZE_LIMIT
            output
          else
            "The output is too large to be sent back directly!"
          end
        end

        def strip_ansi_colorcodes(output)
          output.gsub(/\x1b\[[0-9;]*m/, '')
        end

        def user_ref
          user = pipeline.chat_data.chat_name.user
          user_url = ::Gitlab::Routing.url_helpers.user_url(user)

          "[#{user.name}](#{user_url})"
        end

        def build_ref
          build_url = ::Gitlab::Routing.url_helpers.project_build_url(project, build)

          "[##{build.id}](#{build_url})"
        end
      end
    end
  end
end
