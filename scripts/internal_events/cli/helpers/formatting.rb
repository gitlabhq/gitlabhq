# frozen_string_literal: true

# Helpers related to visual formatting of outputs
module InternalEventsCli
  module Helpers
    module Formatting
      DEFAULT_WINDOW_WIDTH = 100
      DEFAULT_WINDOW_HEIGHT = 30

      # When to format as "info":
      # - When a header is needed to organize contextual
      #   information. These headers should always be all caps.
      # - As a supplemental way to highlight the most important
      #   text within a menu or informational text.
      # - Optionally, for URLs
      def format_info(string)
        pastel.cyan(string)
      end

      # When to format as "warning":
      # - To highlight the first sentence/phrase describing a
      #   problem the user needs to address. Any further text
      #   explantion should be left unformatted.
      # - To highlight an explanation of why the user cannot take
      #   a particular action.
      def format_warning(string)
        pastel.yellow(string)
      end

      # When to format as "selection":
      # - As a supplemental way of indicating something was
      #   selected or the current state of an interaction.
      def format_selection(string)
        pastel.green(string)
      end

      # When to format as "help":
      # - To format supplemental information on how to interact
      #   with prompts. This should always be in parenthesis.
      # - To indicate disabled or unavailable menu options.
      # - To indicate meta-information in menu options or
      #   informational text.
      def format_help(string)
        pastel.bright_black(string)
      end

      # When to format as "prompt":
      # - When we need the user to input information. The text
      #   should describe the action the user should take to move
      #   forward, like `Input text` or `Select one`
      # - As header text on multi-screen steps in a flow. Always
      #   include a counter when this is the case.
      def format_prompt(string)
        pastel.magenta(string)
      end

      # When to format as "error":
      # - When the CLI encounters unexpected problems that may
      #   require broader changes by the Analytics Instrumentation
      #   Group or out of band configuration.
      # - To highlight special characters used to symbolize that
      #   there was an error or that an option is not available.
      def format_error(string)
        pastel.red(string)
      end

      # Strips all existing color/text style
      def clear_format(string)
        pastel.strip(string)
      end

      # When to format as "heading":
      # - At the beginning or end of complete flows, to create
      #   visual separation and indicate logical breakpoints.
      def format_heading(string)
        [divider, pastel.cyan(string), divider].join("\n")
      end

      # Used for grouping prompts that occur on the same screen
      # or as part of the same step of a flow.
      #
      # Counter is exluded if total is 1.
      # The subject's formatting is extended to the counter.
      #
      # @return [String] ex) -- EATING COOKIES (2/3): Chocolate Chip --
      # @param subject [String] describes task generically ex) EATING COOKIES
      # @param item [String] describes specific context ex) Chocolate Chip
      # @param count [Integer] ex) 2
      # @param total [Integer] ex) 3
      def format_subheader(subject, item, count, total)
        formatting_end = "\e[0m"
        suffix = formatting_end if subject[-formatting_end.length..] == formatting_end

        "-- #{[subject.chomp(formatting_end), counter(count, total)].compact.join(' ')}:#{suffix} #{item} --"
      end

      def format_prefix(prefix, string)
        string.lines.map { |line| line.prepend(prefix) }.join
      end

      # When to use a divider:
      # - As separation between whole flows or format the layout
      #   of a screen or the layout of CLI outputs.
      # - Dividers should not be used to differentiate between
      #   prompts on the same screen.
      def divider
        "-" * window_size
      end

      # Prints a progress bar on the screen at the current location
      # @param current_title [String] title to highlight
      # @param titles [Array<String>] progression to follow;
      #     -> first element is expected to be a title for the entire flow
      def progress_bar(current_title, titles = [])
        step = titles.index(current_title)
        total = titles.length - 1

        raise ArgumentError, "Invalid selection #{current_title} in progress bar" unless step

        status = " Step #{step} / #{total} : #{titles.join(' > ')}"
        status.gsub!(current_title, format_selection(current_title))

        total_length = window_size - 4
        step_length = step / total.to_f * total_length

        incomplete = '-' * [(total_length - step_length - 1), 0].max
        complete = '=' * [(step_length - 1), 0].max

        "#{status}\n|==#{complete}>#{incomplete}|\n"
      end

      # Formats a counter if there's anything to count
      #
      # @return [String, nil] ex) "(3/4)""
      def counter(idx, total)
        "(#{idx + 1}/#{total})" if total > 1
      end

      private

      def pastel
        @pastel ||= Pastel.new
      end

      def window_size
        Integer(fetch_window_size)
      rescue StandardError
        DEFAULT_WINDOW_WIDTH
      end

      def window_height
        Integer(fetch_window_height)
      rescue StandardError
        DEFAULT_WINDOW_HEIGHT
      end

      def fetch_window_size
        `tput cols`
      end

      def fetch_window_height
        `tput lines`
      end
    end
  end
end
