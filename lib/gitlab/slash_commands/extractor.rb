module Gitlab
  module SlashCommands
    # This class takes an array of commands that should be extracted from a
    # given text.
    #
    # ```
    # extractor = Gitlab::SlashCommands::Extractor.new([:open, :assign, :labels])
    # ```
    class Extractor
      attr_reader :command_names

      def initialize(command_names)
        @command_names = command_names
      end

      # Extracts commands from content and return an array of commands.
      # The array looks like the following:
      # [
      #   ['command1'],
      #   ['command3', 'arg1 arg2'],
      # ]
      # The command and the arguments are stripped.
      # The original command text is removed from the given `content`.
      #
      # Usage:
      # ```
      # extractor = Gitlab::SlashCommands::Extractor.new([:open, :assign, :labels])
      # msg = %(hello\n/labels ~foo ~"bar baz"\nworld)
      # commands = extractor.extract_commands! #=> [['labels', '~foo ~"bar baz"']]
      # msg #=> "hello\nworld"
      # ```
      def extract_commands!(content)
        return [] unless content

        commands = []

        content.delete!("\r")
        content.gsub!(commands_regex) do
          if $~[:cmd]
            commands << [$~[:cmd], $~[:args]].reject(&:blank?)
            ''
          else
            $~[0]
          end
        end

        commands
      end

      private

      # Builds a regular expression to match known commands.
      # First match group captures the command name and
      # second match group captures its arguments.
      #
      # It looks something like:
      #
      #   /^\/(?<cmd>close|reopen|...)(?:( |$))(?<args>[^\/\n]*)(?:\n|$)/
      def commands_regex
        @commands_regex ||= %r{
            (?<code>
              # Code blocks:
              # ```
              # Anything, including `/cmd args` which are ignored by this filter
              # ```

              ^```
              .+?
              \n```$
            )
          |
            (?<html>
              # HTML block:
              # <tag>
              # Anything, including `/cmd args` which are ignored by this filter
              # </tag>

              ^<[^>]+?>\n
              .+?
              \n<\/[^>]+?>$
            )
          |
            (?<html>
              # Quote block:
              # >>>
              # Anything, including `/cmd args` which are ignored by this filter
              # >>>

              ^>>>
              .+?
              \n>>>$
            )
          |
            (?:
              # Command not in a blockquote, blockcode, or HTML tag:
              # /close

              ^\/(?<cmd>#{command_names.join('|')})(?:(\ |$))(?<args>[^\/\n]*)(?:\n|$)
            )
        }mx
      end
    end
  end
end
