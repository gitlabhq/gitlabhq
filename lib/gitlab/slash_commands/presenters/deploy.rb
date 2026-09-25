# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Deploy < Presenters::Base
        def present(from, to)
          message = "Deployment started from #{from} to #{to}. " \
                    "[Follow its progress](#{resource_url})."

          in_channel_response(text: message)
        end

        def action_not_found
          ephemeral_response(text: "Couldn't find a deployment manual action.")
        end

        def action_failed(message)
          ephemeral_response(text: "Couldn't start the deployment: #{message}")
        end
      end
    end
  end
end
