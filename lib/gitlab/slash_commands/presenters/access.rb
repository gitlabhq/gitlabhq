module Gitlab
  module SlashCommands
    module Presenters
      class Access < Presenters::Base
        def access_denied
          ephemeral_response(text: "Whoops! This action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
        end

        def not_found
          ephemeral_response(text: "404 not found! GitLab couldn't find what you were looking for! :boom:")
        end

        def authorize
          message =
            if @resource
              ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{@resource})."
            else
              ":sweat_smile: Couldn't identify you, nor can I authorize you!"
            end

          ephemeral_response(text: message)
        end

        def unknown_command(commands)
          ephemeral_response(text: help_message(trigger))
        end

        private

        def help_message(trigger)
          header_with_list("Command not found, these are the commands you can use", full_commands(trigger))
        end

        def full_commands(trigger)
          @resource.map { |command| "#{trigger} #{command.help_message}" }
        end
      end
    end
  end
end
