module Gitlab
  module QuickActions
    # This class takes an array of commands that should be extracted from a
    # given text.
    #
    # ```
    # extractor = Gitlab::QuickActions::Extractor.new([:open, :assign, :labels])
    # ```
    class Extractor
      attr_reader :command_definitions

      def initialize(command_definitions)
        @command_definitions = command_definitions
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
      # extractor = Gitlab::QuickActions::Extractor.new([:open, :assign, :labels])
      # msg = %(hello\n/labels ~foo ~"bar baz"\nworld)
      # commands = extractor.extract_commands(msg) #=> [['labels', '~foo ~"bar baz"']]
      # msg #=> "hello\nworld"
      # ```
      def extract_commands(content)
        return [content, []] unless content

        content = content.dup

        commands = []

        content.delete!("\r")
        content.gsub!(commands_regex) do
          if $~[:cmd]
            commands << [$~[:cmd], $~[:arg]].reject(&:blank?)
            ''
          else
            $~[0]
          end
        end

        content, commands = perform_substitutions(content, commands)

        [content.strip, commands]
      end

      private

      # Builds a regular expression to match known commands.
      # First match group captures the command name and
      # second match group captures its arguments.
      #
      # It looks something like:
      #
      #   /^\/(?<cmd>close|reopen|...)(?:( |$))(?<arg>[^\/\n]*)(?:\n|$)/
      def commands_regex
        names = command_names.map(&:to_s)

        @commands_regex ||= %r{
            (?<code>
              # Code blocks:
              # ```
              # Anything, including `/cmd arg` which are ignored by this filter
              # ```

              ^```
              .+?
              \n```$
            )
          |
            (?<html>
              # HTML block:
              # <tag>
              # Anything, including `/cmd arg` which are ignored by this filter
              # </tag>

              ^<[^>]+?>\n
              .+?
              \n<\/[^>]+?>$
            )
          |
            (?<html>
              # Quote block:
              # >>>
              # Anything, including `/cmd arg` which are ignored by this filter
              # >>>

              ^>>>
              .+?
              \n>>>$
            )
          |
            (?:
              # Command not in a blockquote, blockcode, or HTML tag:
              # /close

              ^\/
              (?<cmd>#{Regexp.union(names)})
              (?:
                [ ]
                (?<arg>[^\n]*)
              )?
              (?:\n|$)
            )
        }mx
      end

      def perform_substitutions(content, commands)
        return unless content

        substitution_definitions = self.command_definitions.select do |definition|
          definition.is_a?(Gitlab::QuickActions::SubstitutionDefinition)
        end

        substitution_definitions.each do |substitution|
          match_data = substitution.match(content)
          if match_data
            command = [substitution.name.to_s]
            command << match_data[1] unless match_data[1].empty?
            commands << command
          end

          content = substitution.perform_substitution(self, content)
        end

        [content, commands]
      end

      def command_names
        command_definitions.flat_map do |command|
          next if command.noop?

          command.all_names
        end.compact
      end
    end
  end
end
