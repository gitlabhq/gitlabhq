# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      class Style
        attr_reader :fg, :bg, :mask

        def initialize(fg: nil, bg: nil, mask: 0)
          @fg = fg
          @bg = bg
          @mask = mask

          update_formats
        end

        def update(ansi_commands)
          # treat e\[m as \e[0m
          ansi_commands = ['0'] if ansi_commands.empty?

          evaluate_stack_command(ansi_commands)
        end

        def set?
          @fg || @bg || @formats.any?
        end

        def reset!
          @fg = nil
          @bg = nil
          @mask = 0
          @formats = []
        end

        def ==(other)
          self.to_h == other.to_h
        end

        def to_s
          [@fg, @bg, @formats].flatten.compact.join(' ')
        end

        def to_h
          { fg: @fg, bg: @bg, mask: @mask }
        end

        private

        def evaluate_stack_command(ansi_commands)
          command = ansi_commands.shift
          return unless command

          if changes = Gitlab::Ci::Ansi2json::Parser.new(command, ansi_commands).changes
            apply_changes(changes)
          end

          evaluate_stack_command(ansi_commands)
        end

        def apply_changes(changes)
          case
          when changes[:reset]
            reset!
          when changes.key?(:fg)
            @fg = changes[:fg]
          when changes.key?(:bg)
            @bg = changes[:bg]
          when changes[:enable]
            @mask |= changes[:enable]
          when changes[:disable]
            @mask &= ~changes[:disable]
          else
            return
          end

          update_formats
        end

        def update_formats
          # Most terminals show bold colored text in the light color variant
          # Let's mimic that here
          if @fg.present? && Gitlab::Ci::Ansi2json::Parser.bold?(@mask)
            @fg = @fg.sub(/fg-([a-z]{2,}+)/, 'fg-l-\1')
          end

          @formats = Gitlab::Ci::Ansi2json::Parser.matching_formats(@mask)
        end
      end
    end
  end
end
