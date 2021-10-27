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
      end

      def stream(tokens)
        is_first = true
        token_lines(tokens) do |line|
          yield "\n" unless is_first
          is_first = false

          yield %(<span id="LC#{@line_number}" class="line" lang="#{@tag}">)

          line.each do |token, value|
            yield highlight_unicode_control_characters(span(token, value.chomp! || value))
          end

          yield %(</span>)

          @line_number += 1
        end
      end

      private

      def highlight_unicode_control_characters(text)
        text.gsub(Gitlab::Unicode::BIDI_REGEXP) do |char|
          %(<span class="unicode-bidi has-tooltip" data-toggle="tooltip" title="#{Gitlab::Unicode.bidi_warning}">#{char}</span>)
        end
      end
    end
  end
end
