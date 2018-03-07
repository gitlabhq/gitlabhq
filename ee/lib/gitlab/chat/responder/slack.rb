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
          HTTParty.post(
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
          output =
            if output.empty?
              'The command successfully completed but did not ' \
                'write any data to STDOUT or STDERR.'
            else
              limit_output(output)
            end

          send_response(
            text: message_text(output),
            response_type: RESPONSE_TYPE,
            attachments: [
              {
                color: SUCCESS_COLOR,
                actions: [
                  view_project_button,
                  view_pipeline_button,
                  view_build_button
                ]
              }
            ]
          )
        end

        # Sends the output for a build that failed.
        def failure
          send_response(
            text: message_text('Sorry, the build failed!'),
            response_type: RESPONSE_TYPE,
            attachments: [
              {
                color: FAILURE_COLOR,
                actions: [
                  view_project_button,
                  view_pipeline_button,
                  view_build_button
                ]
              }
            ]
          )
        end

        # Returns the output to send back after a command has been scheduled.
        def scheduled_output
          {
            text: message_text('The command has been scheduled!'),
            attachments: [
              {
                actions: [
                  view_project_button,
                  view_pipeline_button,
                  view_build_button
                ]
              }
            ]
          }
        end

        private

        def limit_output(output)
          if output.bytesize <= MESSAGE_SIZE_LIMIT
            output
          else
            'The command output is too large to be sent back directly. ' \
              "The full output can be found at #{build_url}"
          end
        end

        def mention_user
          "<@#{pipeline.chat_data.chat_name.chat_id}>"
        end

        def message_text(output)
          "#{mention_user}: #{output}"
        end

        def view_project_button
          {
            type: :button,
            text: 'View Project',
            url: url_helpers.project_url(project)
          }
        end

        def view_pipeline_button
          {
            type: :button,
            text: 'View Pipeline',
            url: url_helpers.project_pipeline_url(project, pipeline)
          }
        end

        def view_build_button
          {
            type: :button,
            text: 'View Build',
            url: build_url
          }
        end

        def build_url
          url_helpers.project_build_url(project, build)
        end

        def url_helpers
          ::Gitlab::Routing.url_helpers
        end
      end
    end
  end
end
