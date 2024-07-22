# frozen_string_literal: true

# Helpers related to visual formatting of outputs
module InternalEventsCli
  module Helpers
    module Formatting
      DEFAULT_WINDOW_WIDTH = 100
      DEFAULT_WINDOW_HEIGHT = 30

      def format_info(string)
        pastel.cyan(string)
      end

      def format_warning(string)
        pastel.yellow(string)
      end

      def format_selection(string)
        pastel.green(string)
      end

      def format_help(string)
        pastel.bright_black(string)
      end

      def format_prompt(string)
        pastel.magenta(string)
      end

      def format_error(string)
        pastel.red(string)
      end

      # Strips all existing color/text style
      def clear_format(string)
        pastel.strip(string)
      end

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

      def divider
        "-" * window_size
      end

      def progress_bar(step, total, titles = [])
        breadcrumbs = [
          titles[0..(step - 1)],
          format_selection(titles[step]),
          titles[(step + 1)..]
        ]

        status = " Step #{step} / #{total} : #{breadcrumbs.flatten.join(' > ')}"
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
