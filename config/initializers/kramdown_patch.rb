# frozen_string_literal: true
#
# This pulls in https://github.com/gettalong/kramdown/pull/708 for kramdown v2.3.0.
# Remove this file when that pull request is merged and released.
require 'kramdown/converter'
require 'kramdown/converter/syntax_highlighter/rouge'

module Kramdown::Converter::SyntaxHighlighter
  module Rouge
    def self.formatter_class(opts = {})
      case formatter = opts[:formatter]
      when Class
        formatter
      when /\A[[:upper:]][[:alnum:]_]*\z/
        ::Rouge::Formatters.const_get(formatter, false)
      else
        # Available in Rouge 2.0 or later
        ::Rouge::Formatters::HTMLLegacy
      end
    rescue NameError
      # Fallback to Rouge 1.x
      ::Rouge::Formatters::HTML
    end
  end
end
