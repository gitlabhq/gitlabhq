module Gitlab
  module ChatCommands
    module Presenters
      module Command
        include BasePresenter

        def help_message
          commands = available_commands
          if commands.none?
            ephemeral_response("No commands configured")
          else
            commands.map! { |command| "#{trigger} #{command}" }
            message = header_with_list("Available commands", commands)

            ephemeral_response(message)
          end
        end
      end
    end
  end
end
