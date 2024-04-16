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

      def format_heading(string)
        [divider, pastel.cyan(string), divider].join("\n")
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

      def counter(idx, total)
        format_prompt("(#{idx + 1}/#{total})") if total > 1
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
