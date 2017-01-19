module Gitlab
  module ChatCommands
    module Presenters
      class Help < Presenters::Base
        def present(trigger)
          ephemeral_response(text: help_message(trigger))
        end

        private

        def help_message(trigger)
          if @resource.none?
            "No commands available :thinking_face:"
          else
            header_with_list("Available commands", full_commands(trigger))
          end
        end

        def full_commands(trigger)
          @resource.map { |command| "#{trigger} #{command.help_message}" }
        end
      end
    end
  end
end
