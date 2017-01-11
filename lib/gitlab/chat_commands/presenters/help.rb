module Gitlab::ChatCommands::Presenters
  class Help < Gitlab::ChatCommands::Presenters::Base
    def present(trigger)
      message =
        if @resource.none?
          "No commands available :thinking_face:"
        else
          header_with_list("Available commands", full_commands(trigger))
        end

      ephemeral_response(text: message)
    end

    private

    def full_commands(trigger)
      @resource.map { |command| "#{trigger} #{command.help_message}" }
    end
  end
end
