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
      end
    end
  end
end
