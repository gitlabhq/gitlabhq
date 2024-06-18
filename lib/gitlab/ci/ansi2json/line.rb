# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      # Line class is responsible for keeping the internal state of
      # a log line and to finally serialize it as Hash.
      class Line
        # Line::Segment is a portion of a line that has its own style
        # and text. Multiple segments make the line content.
        class Segment
          include EncodingHelper

          attr_accessor :text, :style

          def initialize(style:)
            @text = +''
            @style = style
          end

          def empty?
            text.empty?
          end

          def to_h
            # Without forcing the encoding to UTF-8 and then replacing
            # invalid UTF-8 sequences we can get an error when serializing
            # the Hash to JSON.
            # Encoding::UndefinedConversionError (or possibly JSON::GeneratorError in json 2.6.1+):
            #   "\xE2" from ASCII-8BIT to UTF-8
            { text: encode_utf8_no_detect(text) }.tap do |result|
              result[:style] = style.to_s if style.set?
            end
          end
        end

        attr_reader :offset, :timestamps, :sections, :segments, :current_segment,
          :section_header, :section_footer, :section_duration,
          :section_options

        def initialize(offset:, style:, sections: [], timestamps: [])
          @offset = offset
          @segments = []
          @sections = sections
          @section_header = false
          @section_footer = false
          @timestamps = timestamps
          @duration = nil
          @at_line_start = true
          @current_segment = Segment.new(style: style)
        end

        def <<(data)
          @current_segment.text << data
          @at_line_start = false
        end

        def clear!
          @at_line_start = true
          @segments.clear
          @current_segment = Segment.new(style: style)
        end

        def style
          @current_segment.style
        end

        def empty?
          @segments.empty? && @current_segment.empty? && @section_duration.nil?
        end

        def at_line_start?
          @at_line_start
        end

        def update_style(ansi_commands)
          @current_segment.style.update(ansi_commands)
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
          normalized_duration_in_seconds = duration_in_seconds.to_i.clamp(0, 1.year)
          duration = ActiveSupport::Duration.build(normalized_duration_in_seconds)
          hours = duration.in_hours.floor
          hours = hours > 0 ? "%02d" % hours : nil
          minutes = "%02d" % duration.parts[:minutes].to_i
          seconds = "%02d" % duration.parts[:seconds].to_i

          @section_duration = [hours, minutes, seconds].compact.join(':')
        end

        def flush_current_segment!
          return if @current_segment.empty?

          @segments << @current_segment.to_h
          @current_segment = Segment.new(style: @current_segment.style)
        end

        def to_h
          flush_current_segment!

          { offset: offset, content: @segments }.tap do |result|
            result[:timestamp] = timestamp if timestamp
            result[:section] = sections.last if sections.any?
            result[:section_header] = true if @section_header
            result[:section_footer] = true if @section_footer
            result[:section_duration] = @section_duration if @section_duration
            result[:section_options] = @section_options if @section_options
          end
        end
      end
    end
  end
end
