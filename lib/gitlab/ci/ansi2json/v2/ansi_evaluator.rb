# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      module V2
        class AnsiEvaluator
          STYLE_BOLD      = 0x01
          STYLE_ITALIC    = 0x02
          STYLE_UNDERLINE = 0x04
          STYLE_CONCEAL   = 0x08
          STYLE_CROSS     = 0x10

          attr_reader :fg, :bg, :mask

          def initialize(fg: nil, bg: nil, mask: 0)
            @fg = fg
            @bg = bg
            @mask = mask
          end

          def apply_commands(commands)
            commands = ['0'] if commands.empty?

            dispatch(commands.shift, commands) until commands.empty?
          end

          def reset!
            @fg = nil
            @bg = nil
            @mask = 0
          end

          def set?
            !@fg.nil? || !@bg.nil? || @mask != 0
          end

          def to_class_string
            return '' unless set?

            parts = []
            parts << @fg if @fg
            parts << @bg if @bg
            parts << 'term-bold'      if (@mask & STYLE_BOLD)      != 0
            parts << 'term-italic'    if (@mask & STYLE_ITALIC)    != 0
            parts << 'term-underline' if (@mask & STYLE_UNDERLINE) != 0
            parts << 'term-conceal'   if (@mask & STYLE_CONCEAL)   != 0
            parts << 'term-cross'     if (@mask & STYLE_CROSS)     != 0
            parts.join(' ')
          end

          def to_h
            { fg: @fg, bg: @bg, mask: @mask }
          end

          private

          # rubocop:disable Lint/DuplicateBranch, Metrics/AbcSize, Metrics/CyclomaticComplexity -- intentional
          def dispatch(cmd, stack)
            case cmd
            when '0'   then reset!
            when '1'   then @mask |=  STYLE_BOLD
            when '3'   then @mask |=  STYLE_ITALIC
            when '4'   then @mask |=  STYLE_UNDERLINE
            when '8'   then @mask |=  STYLE_CONCEAL
            when '9'   then @mask |=  STYLE_CROSS
            when '21', '22' then @mask &= ~STYLE_BOLD
            when '23'  then @mask &= ~STYLE_ITALIC
            when '24'  then @mask &= ~STYLE_UNDERLINE
            when '28'  then @mask &= ~STYLE_CONCEAL
            when '29'  then @mask &= ~STYLE_CROSS

            when '30'  then @fg = 'term-fg-black'
            when '31'  then @fg = 'term-fg-red'
            when '32'  then @fg = 'term-fg-green'
            when '33'  then @fg = 'term-fg-yellow'
            when '34'  then @fg = 'term-fg-blue'
            when '35'  then @fg = 'term-fg-magenta'
            when '36'  then @fg = 'term-fg-cyan'
            when '37'  then @fg = 'term-fg-white'
            when '38'  then @fg = consume_256(stack, 'fg') || @fg
            when '39'  then @fg = nil

            when '40'  then @bg = 'term-bg-black'
            when '41'  then @bg = 'term-bg-red'
            when '42'  then @bg = 'term-bg-green'
            when '43'  then @bg = 'term-bg-yellow'
            when '44'  then @bg = 'term-bg-blue'
            when '45'  then @bg = 'term-bg-magenta'
            when '46'  then @bg = 'term-bg-cyan'
            when '47'  then @bg = 'term-bg-white'
            when '48'  then @bg = consume_256(stack, 'bg') || @bg
            when '49'  then @bg = nil

            when '90'  then @fg = 'term-fg-l-black'
            when '91'  then @fg = 'term-fg-l-red'
            when '92'  then @fg = 'term-fg-l-green'
            when '93'  then @fg = 'term-fg-l-yellow'
            when '94'  then @fg = 'term-fg-l-blue'
            when '95'  then @fg = 'term-fg-l-magenta'
            when '96'  then @fg = 'term-fg-l-cyan'
            when '97'  then @fg = 'term-fg-l-white'
            when '99'  then @fg = nil

            when '100' then @bg = 'term-bg-l-black'
            when '101' then @bg = 'term-bg-l-red'
            when '102' then @bg = 'term-bg-l-green'
            when '103' then @bg = 'term-bg-l-yellow'
            when '104' then @bg = 'term-bg-l-blue'
            when '105' then @bg = 'term-bg-l-magenta'
            when '106' then @bg = 'term-bg-l-cyan'
            when '107' then @bg = 'term-bg-l-white'
            when '109' then @bg = nil
            end
          end
          # rubocop:enable Lint/DuplicateBranch, Metrics/AbcSize, Metrics/CyclomaticComplexity

          def consume_256(stack, prefix)
            return if stack.length < 2 || stack[0] != '5'

            stack.shift
            color_index = stack.shift.to_i
            return if color_index < 0 || color_index > 255

            "xterm-#{prefix}-#{color_index}"
          end
        end
      end
    end
  end
end
