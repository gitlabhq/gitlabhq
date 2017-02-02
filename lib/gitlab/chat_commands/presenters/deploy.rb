module Gitlab
  module ChatCommands
    module Presenters
      class Deploy < Presenters::Base
        def present(from, to)
          message = "Deployment started from #{from} to #{to}. [Follow its progress](#{resource_url})."

          in_channel_response(text: message)
        end

        def no_actions
          ephemeral_response(text: "No action found to be executed")
        end

        def too_many_actions
          ephemeral_response(text: "Too many actions defined")
        end
      end
    end
  end
end
