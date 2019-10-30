# frozen_string_literal: true

module Gitlab
  # Parser/renderer for markups without other special support code.
  module OtherMarkup
    # Public: Converts the provided markup into HTML.
    #
    # input         - the source text in a markup format
    #
    def self.render(file_name, input, context)
      html = GitHub::Markup.render(file_name, input)
        .force_encoding(input.encoding)
      context[:pipeline] ||= :markup

      html = Banzai.render(html, context)

      html.html_safe
    end
  end
end
