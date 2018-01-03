module Gitlab
  module SlashCommands
    module Presenters
      class Help < Presenters::Base
        def present(trigger, text)
          ephemeral_response(text: help_message(trigger, text))
        end

        private

        def help_message(trigger, text)
          return "No commands available :thinking_face:" unless @resource.present?

          if text.start_with?('help')
            header_with_list("Available commands", full_commands(trigger))
          else
            header_with_list("Unknown command, these commands are available", full_commands(trigger))
          end
        end

        def full_commands(trigger)
          @resource.map { |command| "#{trigger} #{command.help_message}" }
        end
      end
    end
  end
end
