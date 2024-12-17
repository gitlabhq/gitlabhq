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
      INLINE_CODE_REGEX = %r{
        (?<inline_code>
          # Inline code on separate rows:
          # `
          # Anything, including `/cmd arg` which are ignored by this filter
          # `

          `.+?`
        )
      }mix

      HTML_BLOCK_REGEX = %r{
        (?<html>
          # HTML block:
          # <tag>
          # Anything, including `/cmd arg` which are ignored by this filter
          # </tag>

          ^<[^>]+?>\n
          .+?
          \n<\/[^>]+?>$
        )
      }mix

      EXCLUSION_REGEX = %r{#{INLINE_CODE_REGEX} | #{HTML_BLOCK_REGEX}}mix

      attr_reader :command_definitions, :keep_actions

      def initialize(command_definitions, keep_actions: false)
        @command_definitions = command_definitions
        @commands_regex = {}
        @keep_actions = keep_actions
      end

      # Extracts commands from content and return an array of commands.
      # The array looks like the following:
      # [
      #   ['command1'],
      #   ['command3', 'arg1 arg2'],
      # ]
      # The original command text and arguments are removed from the given `content`,
      # unless `keep_actions` is true.
      #
      # Usage:
      # ```
      # extractor = Gitlab::QuickActions::Extractor.new([:open, :assign, :labels])
      # msg = %(hello\n/labels ~foo ~"bar baz"\nworld)
      # commands = extractor.extract_commands(msg) #=> [['labels', '~foo ~"bar baz"']]
      # msg #=> "hello\nworld"
      #
      # extractor = Gitlab::QuickActions::Extractor.new([:open, :assign, :labels], keep_actions: true)
      # msg = %(hello\n/labels ~foo ~"bar baz"\nworld)
      # commands = extractor.extract_commands(msg) #=> [['labels', '~foo ~"bar baz"']]
      # msg #=> "hello\n/labels ~foo ~"bar baz"\n\nworld"
      # ```
      def extract_commands(content, only: nil)
        return [content, []] unless content

        perform_regex(content, only: only)
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
        names     = command_names(limit_to_commands: only).map(&:to_s)
        sub_names = substitution_names.map(&:to_s)
        commands  = []
        content   = content.dup
        content.delete!("\r")

        # use a markdown based pipeline to grab possible paragraphs that might
        # contain quick actions. This ensures they are not in HTML blocks, quote blocks,
        # or code blocks.
        pipeline = Banzai::Pipeline::QuickActionPipeline
        possible_paragraphs = pipeline.call(content, {})[:quick_action_paragraphs]

        if possible_paragraphs.present?
          content_lines = content.lines

          # Each paragraph that possibly contains quick actions must be searched. In order
          # to use the `sourcepos` information, we need to convert into individual lines,
          # and then replace the specific lines.
          possible_paragraphs.each do |possible|
            endpos = possible[:end_line]
            endpos += 1 if content_lines[endpos + 1] == "\n"

            paragraph = content_lines[possible[:start_line]..endpos].join

            paragraph.gsub!(commands_regex(names: names, sub_names: sub_names)) do
              command, output = if $~[:substitution]
                                  process_substitutions($~)
                                else
                                  process_commands($~, redact)
                                end

              commands << command
              output
            end

            content_lines.fill('', possible[:start_line]..endpos)
            content_lines[possible[:start_line]] = paragraph
          end

          content = content_lines.join
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
            output = "`/#{matched_text[:cmd]}#{' ' + matched_text[:arg] if matched_text[:arg]}`"
            output += "\n" if matched_text[0].include?("\n")
          elsif keep_actions
            # put the command in a new paragraph, but without introducing newlines
            # so that each command is in its own line, while also preserving sourcemaps
            # of the content that follows.
            output = ActionController::Base.helpers.simple_format(matched_text[0].chomp)
            output += "\n" if matched_text[0].ends_with?("\n")
          end
        end

        [command, output]
      end

      def process_substitutions(matched_text)
        output = matched_text[0]
        command = []

        if matched_text[:substitution]
          cmd = matched_text[:substitution].downcase
          command = [cmd, matched_text[:arg]].reject(&:blank?)

          substitution = substitution_definitions.find { |definition| definition.all_names.include?(cmd.to_sym) }
          output = substitution.perform_substitution(self, output) if substitution
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
      def commands_regex(names:, sub_names:)
        @commands_regex[names] ||= %r{
            #{EXCLUSION_REGEX}
          |
            (?:
              # Command such as:
              # /close

              ^\/
              (?<cmd>#{Regexp.new(Regexp.union(names).source, Regexp::IGNORECASE)})
              (?:
                [ ]
                (?<arg>[^\n]*)
              )?
              (?:\s*\n|$)
            )
          |
            (?:
              # Substitution such as:
              # /shrug

              ^\/
              (?<substitution>#{Regexp.new(Regexp.union(sub_names).source, Regexp::IGNORECASE)})
              (?:
                [ ]
                (?<arg>[^\n]*)
              )?
              (?:\s*\n|$)
            )
        }mix
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

      def substitution_names
        substitution_definitions.flat_map { |command| command.all_names }
          .compact
      end

      def substitution_definitions
        @substition_definitions ||= command_definitions.select do |command|
          command.is_a?(Gitlab::QuickActions::SubstitutionDefinition)
        end
      end
    end
  end
end
