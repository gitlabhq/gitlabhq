# frozen_string_literal: true

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
        @commands_regex = {}
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
      def extract_commands(content, only: nil)
        return [content, []] unless content

        content, commands = perform_regex(content, only: only)

        perform_substitutions(content, commands)
      end

      # Encloses quick action commands into code span markdown
      # avoiding them being executed, for example, when sent via email
      # to GitLab service desk.
      # Example: /label ~label1 becomes `/label ~label1`
      def redact_commands(content)
        return "" unless content

        content, _ = perform_regex(content, redact: true)

        content
      end

      private

      def perform_regex(content, only: nil, redact: false)
        commands = []
        content = content.dup
        content.delete!("\r")

        names = command_names(limit_to_commands: only).map(&:to_s)
        content.gsub!(commands_regex(names: names)) do
          command, output = process_commands($~, redact)
          commands << command
          output
        end

        [content.rstrip, commands.reject(&:empty?)]
      end

      def process_commands(matched_text, redact)
        output = matched_text[0]
        command = []

        if matched_text[:cmd]
          command = [matched_text[:cmd].downcase, matched_text[:arg]].reject(&:blank?)
          output = ''

          if redact
            output = "`/#{matched_text[:cmd]}#{" " + matched_text[:arg] if matched_text[:arg]}`"
            output += "\n" if matched_text[0].include?("\n")
          end
        end

        [command, output]
      end

      # Builds a regular expression to match known commands.
      # First match group captures the command name and
      # second match group captures its arguments.
      #
      # It looks something like:
      #
      #   /^\/(?<cmd>close|reopen|...)(?:( |$))(?<arg>[^\/\n]*)(?:\n|$)/
      def commands_regex(names:)
        @commands_regex[names] ||= %r{
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
              (?<cmd>#{Regexp.new(Regexp.union(names).source, Regexp::IGNORECASE)})
              (?:
                [ ]
                (?<arg>[^\n]*)
              )?
              (?:\s*\n|$)
            )
        }mix
      end

      def perform_substitutions(content, commands)
        return unless content

        substitution_definitions = self.command_definitions.select do |definition|
          definition.is_a?(Gitlab::QuickActions::SubstitutionDefinition)
        end

        substitution_definitions.each do |substitution|
          regex = commands_regex(names: substitution.all_names)
          content = content.gsub(regex) do |text|
            if $~[:cmd]
              command = [substitution.name.to_s]
              command << $~[:arg] if $~[:arg].present?
              commands << command

              substitution.perform_substitution(self, text)
            else
              text
            end
          end
        end

        [content, commands]
      end

      def command_names(limit_to_commands:)
        command_definitions.flat_map do |command|
          next if command.noop?

          if limit_to_commands && (command.all_names & limit_to_commands).empty?
            next
          end

          command.all_names
        end.compact
      end
    end
  end
end
