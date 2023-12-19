# frozen_string_literal: true

# Helpers related to configuration of TTY::Prompt prompts
module InternalEventsCli
  module Helpers
    module CliInputs
      def prompt_for_array_selection(message, choices, default = nil, &formatter)
        formatter ||= ->(choice) { choice.sort.join(", ") }

        choices = choices.map do |choice|
          { name: formatter.call(choice), value: choice }
        end

        cli.select(message, choices, **select_opts) do |menu|
          menu.enum "."
          menu.default formatter.call(default) if default
        end
      end

      def prompt_for_text(message, value = nil)
        help_message = "(enter to #{value ? 'submit' : 'skip'})"

        cli.ask(
          "#{message} #{format_help(help_message)}",
          value: value || '',
          **input_opts
        )
      end

      def input_opts
        { prefix: format_prompt('Input text: ') }
      end

      def yes_no_opts
        { prefix: format_prompt('Yes/No: ') }
      end

      def select_opts
        { prefix: format_prompt('Select one: '), cycle: true, show_help: :always }
      end

      def multiselect_opts
        { prefix: format_prompt('Select multiple: '), cycle: true, show_help: :always, min: 1 }
      end

      # Accepts a number of lines occupied by text, so remaining
      # screen real estate can be filled with select options
      def filter_opts(header_size: nil)
        {
          filter: true,
          per_page: header_size ? [(window_height - header_size), 10].max : 30
        }
      end

      def input_required_text
        format_help("(leave blank for help)")
      end
    end
  end
end
