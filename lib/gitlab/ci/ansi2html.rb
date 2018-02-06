# ANSI color library
#
# Implementation per http://en.wikipedia.org/wiki/ANSI_escape_code
module Gitlab
  module Ci
    module Ansi2html
      # keys represent the trailing digit in color changing command (30-37, 40-47, 90-97. 100-107)
      COLOR = {
        0 => 'black', # not that this is gray in the intense color table
        1 => 'red',
        2 => 'green',
        3 => 'yellow',
        4 => 'blue',
        5 => 'magenta',
        6 => 'cyan',
        7 => 'white', # not that this is gray in the dark (aka default) color table
      }.freeze

      STYLE_SWITCHES = {
        bold:       0x01,
        italic:     0x02,
        underline:  0x04,
        conceal:    0x08,
        cross:      0x10
      }.freeze

      def self.convert(ansi, state = nil)
        Converter.new.convert(ansi, state)
      end

      class Converter
        def on_0(s) reset()                            end

        def on_1(s) enable(STYLE_SWITCHES[:bold])      end

        def on_3(s) enable(STYLE_SWITCHES[:italic])    end

        def on_4(s) enable(STYLE_SWITCHES[:underline]) end

        def on_8(s) enable(STYLE_SWITCHES[:conceal])   end

        def on_9(s) enable(STYLE_SWITCHES[:cross])     end

        def on_21(s) disable(STYLE_SWITCHES[:bold])      end

        def on_22(s) disable(STYLE_SWITCHES[:bold])      end

        def on_23(s) disable(STYLE_SWITCHES[:italic])    end

        def on_24(s) disable(STYLE_SWITCHES[:underline]) end

        def on_28(s) disable(STYLE_SWITCHES[:conceal])   end

        def on_29(s) disable(STYLE_SWITCHES[:cross])     end

        def on_30(s) set_fg_color(0) end

        def on_31(s) set_fg_color(1) end

        def on_32(s) set_fg_color(2) end

        def on_33(s) set_fg_color(3) end

        def on_34(s) set_fg_color(4) end

        def on_35(s) set_fg_color(5) end

        def on_36(s) set_fg_color(6) end

        def on_37(s) set_fg_color(7) end

        def on_38(s) set_fg_color_256(s) end

        def on_39(s) set_fg_color(9) end

        def on_40(s) set_bg_color(0) end

        def on_41(s) set_bg_color(1) end

        def on_42(s) set_bg_color(2) end

        def on_43(s) set_bg_color(3) end

        def on_44(s) set_bg_color(4) end

        def on_45(s) set_bg_color(5) end

        def on_46(s) set_bg_color(6) end

        def on_47(s) set_bg_color(7) end

        def on_48(s) set_bg_color_256(s) end

        def on_49(s) set_bg_color(9) end

        def on_90(s) set_fg_color(0, 'l') end

        def on_91(s) set_fg_color(1, 'l') end

        def on_92(s) set_fg_color(2, 'l') end

        def on_93(s) set_fg_color(3, 'l') end

        def on_94(s) set_fg_color(4, 'l') end

        def on_95(s) set_fg_color(5, 'l') end

        def on_96(s) set_fg_color(6, 'l') end

        def on_97(s) set_fg_color(7, 'l') end

        def on_99(s) set_fg_color(9, 'l') end

        def on_100(s) set_bg_color(0, 'l') end

        def on_101(s) set_bg_color(1, 'l') end

        def on_102(s) set_bg_color(2, 'l') end

        def on_103(s) set_bg_color(3, 'l') end

        def on_104(s) set_bg_color(4, 'l') end

        def on_105(s) set_bg_color(5, 'l') end

        def on_106(s) set_bg_color(6, 'l') end

        def on_107(s) set_bg_color(7, 'l') end

        def on_109(s) set_bg_color(9, 'l') end

        attr_accessor :offset, :n_open_tags, :fg_color, :bg_color, :style_mask

        STATE_PARAMS = [:offset, :n_open_tags, :fg_color, :bg_color, :style_mask].freeze

        def convert(stream, new_state)
          reset_state
          restore_state(new_state, stream) if new_state.present?

          append = false
          truncated = false

          cur_offset = stream.tell
          if cur_offset > @offset
            @offset = cur_offset
            truncated = true
          else
            stream.seek(@offset)
            append = @offset > 0
          end

          start_offset = @offset

          open_new_tag

          stream.each_line do |line|
            s = StringScanner.new(line)
            until s.eos?

              if s.scan(Gitlab::Regex.build_trace_section_regex)
                handle_section(s)
              elsif s.scan(/\e([@-_])(.*?)([@-~])/)
                handle_sequence(s)
              elsif s.scan(/\e(([@-_])(.*?)?)?$/)
                break
              elsif s.scan(/</)
                @out << '&lt;'
              elsif s.scan(/\r?\n/)
                @out << '<br>'
              else
                @out << s.scan(/./m)
              end

              @offset += s.matched_size
            end
          end

          close_open_tags()

          OpenStruct.new(
            html: @out.force_encoding(Encoding.default_external),
            state: state,
            append: append,
            truncated: truncated,
            offset: start_offset,
            size: stream.tell - start_offset,
            total: stream.size
          )
        end

        def handle_section(s)
          action = s[1]
          timestamp = s[2]
          section = s[3]
          line = s.matched()[0...-5] # strips \r\033[0K

          @out << %{<div class="hidden" data-action="#{action}" data-timestamp="#{timestamp}" data-section="#{section}">#{line}</div>}
        end

        def handle_sequence(s)
          indicator = s[1]
          commands = s[2].split ';'
          terminator = s[3]

          # We are only interested in color and text style changes - triggered by
          # sequences starting with '\e[' and ending with 'm'. Any other control
          # sequence gets stripped (including stuff like "delete last line")
          return unless indicator == '[' && terminator == 'm'

          close_open_tags()

          if commands.empty?()
            reset()
            return
          end

          evaluate_command_stack(commands)

          open_new_tag
        end

        def evaluate_command_stack(stack)
          return unless command = stack.shift()

          if self.respond_to?("on_#{command}", true)
            self.__send__("on_#{command}", stack) # rubocop:disable GitlabSecurity/PublicSend
          end

          evaluate_command_stack(stack)
        end

        def open_new_tag
          css_classes = []

          unless @fg_color.nil?
            fg_color = @fg_color
            # Most terminals show bold colored text in the light color variant
            # Let's mimic that here
            if @style_mask & STYLE_SWITCHES[:bold] != 0
              fg_color.sub!(/fg-([a-z]{2,}+)/, 'fg-l-\1')
            end

            css_classes << fg_color
          end

          css_classes << @bg_color unless @bg_color.nil?

          STYLE_SWITCHES.each do |css_class, flag|
            css_classes << "term-#{css_class}" if @style_mask & flag != 0
          end

          return if css_classes.empty?

          @out << %{<span class="#{css_classes.join(' ')}">}
          @n_open_tags += 1
        end

        def close_open_tags
          while @n_open_tags > 0
            @out << %{</span>}
            @n_open_tags -= 1
          end
        end

        def reset_state
          @offset = 0
          @n_open_tags = 0
          @out = ''
          reset
        end

        def state
          state = STATE_PARAMS.inject({}) do |h, param|
            h[param] = send(param) # rubocop:disable GitlabSecurity/PublicSend
            h
          end
          Base64.urlsafe_encode64(state.to_json)
        end

        def restore_state(new_state, stream)
          state = Base64.urlsafe_decode64(new_state)
          state = JSON.parse(state, symbolize_names: true)
          return if state[:offset].to_i > stream.size

          STATE_PARAMS.each do |param|
            send("#{param}=".to_sym, state[param]) # rubocop:disable GitlabSecurity/PublicSend
          end
        end

        def reset
          @fg_color = nil
          @bg_color = nil
          @style_mask = 0
        end

        def enable(flag)
          @style_mask |= flag
        end

        def disable(flag)
          @style_mask &= ~flag
        end

        def set_fg_color(color_index, prefix = nil)
          @fg_color = get_term_color_class(color_index, ["fg", prefix])
        end

        def set_bg_color(color_index, prefix = nil)
          @bg_color = get_term_color_class(color_index, ["bg", prefix])
        end

        def get_term_color_class(color_index, prefix)
          color_name = COLOR[color_index]
          return nil if color_name.nil?

          get_color_class(["term", prefix, color_name])
        end

        def set_fg_color_256(command_stack)
          css_class = get_xterm_color_class(command_stack, "fg")
          @fg_color = css_class unless css_class.nil?
        end

        def set_bg_color_256(command_stack)
          css_class = get_xterm_color_class(command_stack, "bg")
          @bg_color = css_class unless css_class.nil?
        end

        def get_xterm_color_class(command_stack, prefix)
          # the 38 and 48 commands have to be followed by "5" and the color index
          return unless command_stack.length >= 2
          return unless command_stack[0] == "5"

          command_stack.shift() # ignore the "5" command
          color_index = command_stack.shift().to_i

          return unless color_index >= 0
          return unless color_index <= 255

          get_color_class(["xterm", prefix, color_index])
        end

        def get_color_class(segments)
          [segments].flatten.compact.join('-')
        end
      end
    end
  end
end
