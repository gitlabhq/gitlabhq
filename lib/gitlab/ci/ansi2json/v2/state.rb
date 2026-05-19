# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      module V2
        # Subclass of v1::State that constructs V2::Line and reuses the same
        # Line instance across input lines (the previous line's @segments and
        # @current_text were transferred to its emitted hash on to_h, so
        # resetting in place is safe). HMAC encoding, signature handling,
        # section tracking, and style restoration are inherited unchanged:
        # those are the contract shared with v1.
        class State < ::Gitlab::Ci::Ansi2json::State
          def new_line!(timestamps: [], offset: nil, style: nil)
            inherited_style = style || @current_line.style
            line_offset = offset || @offset
            sections = @open_sections.keys

            if @current_line
              @current_line.reset!(
                offset: line_offset,
                timestamps: timestamps,
                style: inherited_style,
                sections: sections
              )
            else
              @current_line = Line.new(
                offset: line_offset,
                timestamps: timestamps,
                style: inherited_style,
                sections: sections
              )
            end
          end
        end
      end
    end
  end
end
