module Gitlab
  # Parser/renderer for markups without other special support code.
  module OtherMarkup
    # Public: Converts the provided markup into HTML.
    #
    # input         - the source text in a markup format
    #
    def self.render(file_name, input)
      html = GitHub::Markup.render(file_name, input).
        force_encoding(input.encoding)

      filter = Banzai::Filter::SanitizationFilter.new(html)
      html = filter.call.to_s

      html.html_safe
    end
  end
end
