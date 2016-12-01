module Gitlab::ChatCommands::Presenters
  class Deploy < Gitlab::ChatCommands::Presenters::BasePresenter
    def execute(from,to)
      message = format("Deployment from #{from} to #{to} started. [Follow its progress](#{resource_url}).")
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
