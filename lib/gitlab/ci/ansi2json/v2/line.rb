# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      module V2
        class Line
          include EncodingHelper

          attr_reader :offset, :timestamps, :sections, :style

          def initialize(offset:, style:, sections: [], timestamps: [])
            reset!(offset: offset, style: style, sections: sections, timestamps: timestamps)
          end

          # @segments and @current_text get transferred into the previous
          # line's emitted Hash on to_h, so we always allocate fresh ones here
          # rather than mutating shared state.
          def reset!(offset:, style:, sections: [], timestamps: [])
            @offset = offset
            @style = style
            @sections = sections
            @timestamps = timestamps
            @segments = []
            @current_text = +''
            @section_header = false
            @section_footer = false
            @section_duration = nil
            @section_options = nil
            @at_line_start = true
          end

          def <<(data)
            @current_text << data
            @at_line_start = false
          end

          # State#update_style flushes the current segment before calling
          # this, so we don't flush again here.
          def update_style(commands)
            @style.apply_commands(commands)
          end

          def flush_current_segment!
            return if @current_text.empty?

            seg = { text: encode_utf8_no_detect(@current_text) }
            seg[:style] = @style.to_class_string if @style.set?
            @segments << seg
            @current_text = +''
          end

          def clear!
            @at_line_start = true
            @segments.clear
            @current_text = +''
          end

          def empty?
            @segments.empty? && @current_text.empty? && @section_duration.nil?
          end

          def at_line_start?
            @at_line_start
          end

          def timestamp
            @timestamps.last
          end

          def add_timestamp(value)
            @timestamps << value if value
          end

          def add_section(section)
            @at_line_start = false
            @sections << section
          end

          def set_section_options(options)
            @section_options = options
          end

          def set_as_section_header
            @section_header = true
          end

          def set_as_section_footer
            @section_footer = true
          end

          def set_section_duration(duration_in_seconds)
            normalized = duration_in_seconds.to_i.clamp(0, 1.year)
            duration = ActiveSupport::Duration.build(normalized)
            hours = duration.in_hours.floor
            hours = hours > 0 ? format('%02d', hours) : nil
            minutes = format('%02d', duration.parts[:minutes].to_i)
            seconds = format('%02d', duration.parts[:seconds].to_i)
            @section_duration = [hours, minutes, seconds].compact.join(':')
          end

          # Key insertion order is significant: it must match v1::Line#to_h
          # exactly so the produced hashes compare equal under shared examples.
          def to_h
            flush_current_segment!

            result = { offset: @offset, content: @segments }
            result[:timestamp] = @timestamps.last if @timestamps.last
            result[:section] = @sections.last if @sections.any?
            result[:section_header] = true if @section_header
            result[:section_footer] = true if @section_footer
            result[:section_duration] = @section_duration if @section_duration
            result[:section_options] = @section_options if @section_options
            result
          end
        end
      end
    end
  end
end
