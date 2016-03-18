module Gitlab
  # Parser/renderer for markups without other special support code.
  module OtherMarkup

    # Public: Converts the provided markup into HTML.
    #
    # input         - the source text in a markup format
    # context       - a Hash with the template context:
    #                 :commit
    #                 :project
    #                 :project_wiki
    #                 :requested_path
    #                 :ref
    #
    def self.render(file_name, input, context)
      html = GitHub::Markup.render(file_name, input).
        force_encoding(input.encoding)

      html = Banzai.post_process(html, context)

      html.html_safe
    end
  end
end
