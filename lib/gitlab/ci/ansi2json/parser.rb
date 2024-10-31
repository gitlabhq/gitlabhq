# frozen_string_literal: true

# This Parser translates ANSI escape codes into human readable format.
# It considers color and format changes.
# Inspired by http://en.wikipedia.org/wiki/ANSI_escape_code
module Gitlab
  module Ci
    module Ansi2json
      class Parser
        # keys represent the trailing digit in color changing command (30-37, 40-47, 90-97. 100-107)
        COLOR = {
          0 => 'black', # Note: This is gray in the intense color table.
          1 => 'red',
          2 => 'green',
          3 => 'yellow',
          4 => 'blue',
          5 => 'magenta',
          6 => 'cyan',
          7 => 'white' # Note: This is gray in the dark (aka default) color table.
        }.freeze

        STYLE_SWITCHES = {
          bold: 0x01,
          italic: 0x02,
          underline: 0x04,
          conceal: 0x08,
          cross: 0x10
        }.freeze

        def self.bold?(mask)
          mask & STYLE_SWITCHES[:bold] != 0
        end

        def self.matching_formats(mask)
          formats = []
          STYLE_SWITCHES.each do |text_format, flag|
            formats << "term-#{text_format}" if (mask & flag) != 0
          end

          formats
        end

        def initialize(command, ansi_stack = nil)
          @command = command
          @ansi_stack = ansi_stack
        end

        def changes
          try("on_#{@command}", @ansi_stack)
        end

        # rubocop:disable Style/SingleLineMethods
        def on_0(_) { reset: true } end

        def on_1(_) { enable: STYLE_SWITCHES[:bold] } end

        def on_3(_) { enable: STYLE_SWITCHES[:italic] } end

        def on_4(_) { enable: STYLE_SWITCHES[:underline] } end

        def on_8(_) { enable: STYLE_SWITCHES[:conceal] } end

        def on_9(_) { enable: STYLE_SWITCHES[:cross] } end

        def on_21(_) { disable: STYLE_SWITCHES[:bold] } end

        def on_22(_) { disable: STYLE_SWITCHES[:bold] } end

        def on_23(_) { disable: STYLE_SWITCHES[:italic] } end

        def on_24(_) { disable: STYLE_SWITCHES[:underline] } end

        def on_28(_) { disable: STYLE_SWITCHES[:conceal] } end

        def on_29(_) { disable: STYLE_SWITCHES[:cross] } end

        def on_30(_) { fg: fg_color(0) } end

        def on_31(_) { fg: fg_color(1) } end

        def on_32(_) { fg: fg_color(2) } end

        def on_33(_) { fg: fg_color(3) } end

        def on_34(_) { fg: fg_color(4) } end

        def on_35(_) { fg: fg_color(5) } end

        def on_36(_) { fg: fg_color(6) } end

        def on_37(_) { fg: fg_color(7) } end

        def on_38(stack) { fg: fg_color_256(stack) } end

        def on_39(_) { fg: nil } end

        def on_40(_) { bg: bg_color(0) } end

        def on_41(_) { bg: bg_color(1) } end

        def on_42(_) { bg: bg_color(2) } end

        def on_43(_) { bg: bg_color(3) } end

        def on_44(_) { bg: bg_color(4) } end

        def on_45(_) { bg: bg_color(5) } end

        def on_46(_) { bg: bg_color(6) } end

        def on_47(_) { bg: bg_color(7) } end

        def on_48(stack) { bg: bg_color_256(stack) } end

        def on_49(_) { bg: nil } end

        def on_90(_) { fg: fg_color(0, 'l') } end

        def on_91(_) { fg: fg_color(1, 'l') } end

        def on_92(_) { fg: fg_color(2, 'l') } end

        def on_93(_) { fg: fg_color(3, 'l') } end

        def on_94(_) { fg: fg_color(4, 'l') } end

        def on_95(_) { fg: fg_color(5, 'l') } end

        def on_96(_) { fg: fg_color(6, 'l') } end

        def on_97(_) { fg: fg_color(7, 'l') } end

        def on_99(_) { fg: fg_color(9, 'l') } end

        def on_100(_) { fg: bg_color(0, 'l') } end

        def on_101(_) { fg: bg_color(1, 'l') } end

        def on_102(_) { fg: bg_color(2, 'l') } end

        def on_103(_) { fg: bg_color(3, 'l') } end

        def on_104(_) { fg: bg_color(4, 'l') } end

        def on_105(_) { fg: bg_color(5, 'l') } end

        def on_106(_) { fg: bg_color(6, 'l') } end

        def on_107(_) { fg: bg_color(7, 'l') } end

        def on_109(_) { fg: bg_color(9, 'l') } end
        # rubocop:enable Style/SingleLineMethods

        def fg_color(color_index, prefix = nil)
          term_color_class(color_index, ['fg', prefix])
        end

        def fg_color_256(command_stack)
          xterm_color_class(command_stack, 'fg')
        end

        def bg_color(color_index, prefix = nil)
          term_color_class(color_index, ['bg', prefix])
        end

        def bg_color_256(command_stack)
          xterm_color_class(command_stack, 'bg')
        end

        def term_color_class(color_index, prefix)
          color_name = COLOR[color_index]
          return if color_name.nil?

          color_class(['term', prefix, color_name])
        end

        def xterm_color_class(command_stack, prefix)
          # the 38 and 48 commands have to be followed by "5" and the color index
          return unless command_stack.length >= 2
          return unless command_stack[0] == "5"

          command_stack.shift # ignore the "5" command
          color_index = command_stack.shift.to_i

          return unless color_index >= 0
          return unless color_index <= 255

          color_class(["xterm", prefix, color_index])
        end

        def color_class(segments)
          [segments].flatten.compact.join('-')
        end
      end
    end
  end
end
