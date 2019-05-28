# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Run < Presenters::Base
        # rubocop: disable CodeReuse/ActiveRecord
        def present(pipeline)
          build = pipeline.builds.take

          if build && (responder = Chat::Responder.responder_for(build))
            in_channel_response(responder.scheduled_output)
          else
            unsupported_chat_service
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def unsupported_chat_service
          ephemeral_response(text: 'Sorry, this chat service is currently not supported by GitLab ChatOps.')
        end

        def failed_to_schedule(command)
          ephemeral_response(
            text: 'The command could not be scheduled. Make sure that your ' \
              'project has a .gitlab-ci.yml that defines a job with the ' \
              "name #{command.inspect}"
          )
        end
      end
    end
  end
end
