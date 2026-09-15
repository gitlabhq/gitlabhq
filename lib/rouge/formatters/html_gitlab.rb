# frozen_string_literal: true

module Rouge
  module Formatters
    class HTMLGitlab < Rouge::Formatters::HTML
      tag 'html_gitlab'

      # Creates a new <tt>Rouge::Formatter::HTMLGitlab</tt> instance.
      #
      # [+tag+]          The tag (language) of the lexer used to generate the formatted tokens
      # [+line_number+]  The line number used to populate line IDs
      def initialize(options = {})
        @tag = options[:tag]
        @line_number = options[:line_number] || 1
        @suppress_line_ids = options[:suppress_line_ids]
        @ellipsis_indexes = options[:ellipsis_indexes] || []
        @ellipsis_svg = options[:ellipsis_svg]
      end

      def stream(tokens)
        is_first = true
        token_lines(tokens) do |line|
          yield "\n" unless is_first
          is_first = false

          id = " id=\"LC#{@line_number}\"" unless @suppress_line_ids
          language_tag = @tag.presence || 'plaintext'
          data_lang = " data-lang=\"#{language_tag}\""

          yield %(<span#{id} class="line"#{data_lang}>)

          line.each do |token, value|
            value = value.chomp! || value
            value = replace_space_characters(value)

            yield highlight_unicode_control_characters(span(token, value))
          end

          yield ellipsis if @ellipsis_indexes.include?(@line_number - 1) && @ellipsis_svg.present?

          yield %(</span>)

          @line_number += 1
        end
      end

      protected

      # Replaces a poor performing version from rouge
      # https://github.com/rouge-ruby/rouge/blob/16e6ecdb3bc4248cead78375e1b24580ee2352a1/lib/rouge/formatter.rb#L92
      def token_lines(tokens, &block)
        return enum_for(:token_lines, tokens) unless block

        line = []
        tokens.each do |token, value|
          segments = value.split("\n", -1)
          final_segment = segments.pop

          segments.each do |segment|
            line << [token, segment] unless segment.empty?
            yield line
            line = []
          end

          line << [token, final_segment] if final_segment && !final_segment.empty?
        end

        yield line if line.any?
      end

      private

      def ellipsis
        %(<span class="gl-px-2 gl-rounded-base gl-mx-2 gl-bg-gray-100 gl-cursor-help has-tooltip" title="Content has been trimmed">#{@ellipsis_svg}</span>)
      end

      def replace_space_characters(text)
        return text if text.ascii_only?
        return text unless Gitlab::Unicode::NON_ASCII_SPACE_REGEXP.match?(text)

        text.tr(Gitlab::Unicode::NON_ASCII_SPACE_CHARACTERS, ' ')
      end

      def highlight_unicode_control_characters(text)
        return text if text.ascii_only?
        return text unless Gitlab::Unicode::BIDI_CONTROL_REGEXP.match?(text)

        text.gsub(Gitlab::Unicode::BIDI_CONTROL_REGEXP) do |char|
          %(<span class="unicode-bidi has-tooltip" data-toggle="tooltip" title="#{Gitlab::Unicode.bidi_warning}">#{char}</span>)
        end
      end
    end
  end
end
