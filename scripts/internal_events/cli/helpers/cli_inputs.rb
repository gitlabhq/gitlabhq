# frozen_string_literal: true

# Helpers related to configuration of TTY::Prompt prompts
module InternalEventsCli
  module Helpers
    module CliInputs
      def prompt_for_array_selection(message, choices, default = nil, **opts, &formatter)
        formatter ||= ->(choice) { choice.sort.join(", ") }

        choices = choices.map do |choice|
          { name: formatter.call(choice), value: choice }
        end

        cli.select(message, choices, **select_opts, **opts) do |menu|
          menu.enum "."
          menu.default formatter.call(default) if default
        end
      end

      # Prompts the user to input text. Prefer this over calling cli#ask directly (so styling is consistent).
      #
      #
      # @return [String, nil] user-provided text
      # @param message [String] a single line prompt/question or last line of a prompt
      # @param value [String, nil] prepopulated as the answer which user can accept/modify
      # @option multiline [Boolean] indicates that any help text or prompt prefix will be printed on another line
      #                             before calling #prompt_for_text -->  ex) see MetricDefiner#prompt_for_description
      # @yield [TTY::Prompt::Question]
      # @see https://github.com/piotrmurach/tty-prompt?tab=readme-ov-file#21-ask
      def prompt_for_text(message, value = nil, multiline: false, **opts)
        prompt = message.dup # mutable for concat in #ask callback

        options = { **input_opts, **opts }
        value ||= options.delete(:value)
        options.delete(:prefix) if multiline

        cli.ask(prompt, **options) do |q|
          q.value(value) if value

          yield q if block_given?

          if multiline
            # wrap error messages so they render nicely with prompt
            q.messages.each do |key, error|
              closing_text = "\n#{format_error('<<|')}" if error.lines.length > 1

              q.messages[key] = [error, closing_text, "\n\n\n"].join('')
            end
          else
            # append help text only if this line includes the formatted 'prompt' prefix,
            # otherwise depend on the caller to print the help text if needed
            prompt.concat(" #{q.required ? input_required_text : input_optional_text(value)}")
          end
        end
      end

      def input_opts
        { prefix: format_prompt('Input text: ') }
      end

      def yes_no_opts
        { prefix: format_prompt('Yes/No: ') }
      end

      # Provide to cli#select as kwargs for consistent style/ux
      def select_opts
        {
          prefix: format_prompt('Select one: '),
          cycle: true,
          show_help: :always,
          # Strip colors so #format_selection is applied uniformly
          active_color: ->(choice) { format_selection(clear_format(choice)) }
        }
      end

      # Provide to cli#multiselect as kwargs for consistent style/ux
      def multiselect_opts
        {
          **select_opts,
          prefix: format_prompt('Select multiple: '),
          min: 1,
          help: "(Space to select, Enter to submit, ↑/↓/←/→ to move, Ctrl+A|R to select all|none, letters to filter)"
        }
      end

      # Accepts a number of lines occupied by text, so remaining
      # screen real estate can be filled with select options
      def filter_opts(header_size: nil)
        {
          filter: true,
          per_page: header_size ? [(window_height - header_size), 10].max : 30
        }
      end

      # Creates divider to be passed to a select or multiselect
      # as a menu item. Use with #format_disabled_options_as_dividers
      # for best formatting.
      def select_option_divider(text)
        { name: "-- #{text} --", value: nil, disabled: '' }
      end

      # Styling all disabled options in a menu without indication
      # of being a selectable option
      # @param select_menu [TTY::Prompt]
      def format_disabled_options_as_dividers(select_menu)
        select_menu.symbols(cross: '')
      end

      # For use when menu options are disabled by being grayed out
      def disabled_format_callback
        proc { |menu| menu.symbols(cross: format_help("✘")) }
      end

      # Help text to use with required, multiline cli#ask prompts.
      # Otherwise, prefer #prompt_for_text.
      def input_required_text
        format_help("(leave blank for help)")
      end

      # Help text to use with optional, multiline cli#ask prompts.
      # Otherwise, prefer #prompt_for_text.
      def input_optional_text(value)
        format_help("(enter to #{value ? 'submit' : 'skip'})")
      end

      def disableable_option(value:, disabled:, name: nil)
        should_disable = yield
        name ||= value

        {
          value: value,
          name: (should_disable ? format_help(name) : name),
          disabled: (disabled if should_disable)
        }
      end
    end
  end
end
