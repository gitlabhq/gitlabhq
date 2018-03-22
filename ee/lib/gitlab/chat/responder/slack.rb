# frozen_string_literal: true

module Gitlab
  module Chat
    module Responder
      class Slack < Responder::Base
        SUCCESS_COLOR = '#B3ED8E'
        FAILURE_COLOR = '#FF5640'
        RESPONSE_TYPE = :in_channel

        # Slack breaks messages apart if they're around 4 KB in size. We use a
        # slightly smaller limit here to account for user mentions.
        MESSAGE_SIZE_LIMIT = 3.5.kilobytes

        # Sends a response back to Slack
        #
        # output - The output to send back to Slack, as a Hash.
        def send_response(output)
          Gitlab::HTTP.post(
            pipeline.chat_data.response_url,
            {
              headers: { Accept: 'application/json' },
              body: output.to_json
            }
          )
        end

        # Sends the output for a build that completed successfully.
        #
        # output - The output produced by the chat command.
        def success(output)
          return if output.empty?

          send_response(
            text: message_text(limit_output(output)),
            response_type: RESPONSE_TYPE
          )
        end

        # Sends the output for a build that failed.
        def failure
          send_response(
            text: message_text("<#{build_url}|Sorry, the build failed!>"),
            response_type: RESPONSE_TYPE
          )
        end

        # Returns the output to send back after a command has been scheduled.
        def scheduled_output
          {
            text: message_text("<#{build_url}|The command has been scheduled!>")
          }
        end

        private

        def limit_output(output)
          if output.bytesize <= MESSAGE_SIZE_LIMIT
            output
          else
            "<#{build_url}|The output is too large to be sent back directly!>"
          end
        end

        def mention_user
          "<@#{pipeline.chat_data.chat_name.chat_id}>"
        end

        def message_text(output)
          "#{mention_user}: #{output}"
        end

        def build_url
          ::Gitlab::Routing.url_helpers.project_build_url(project, build)
        end
      end
    end
  end
end
