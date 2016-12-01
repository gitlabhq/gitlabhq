module Gitlab::ChatCommands::Presenters
  class Command < BasePresenter
    def help(commands, trigger)
      if commands.none?
        ephemeral_response(text: "No commands configured")
      else
        commands.map! { |command| "#{trigger} #{command.help_message}" }
        message = header_with_list("Available commands", commands)
        ephemeral_response(text: message)
      end
    end
  end
end
