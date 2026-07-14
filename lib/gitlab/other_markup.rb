# frozen_string_literal: true

module Gitlab
  # Parser/renderer for markups without other special support code.
  module OtherMarkup
    RENDER_TIMEOUT = 10.seconds

    # Public: Converts the provided markup into HTML.
    #
    # input         - the source text in a markup format
    #
    def self.render(file_name, input, context)
      html = Gitlab::RenderTimeout.timeout(foreground: RENDER_TIMEOUT) do
        GitHub::Markup.render(file_name, input)
      end.force_encoding(input.encoding)

      context[:pipeline] ||= if Gitlab::MarkupHelper.org_mode?(file_name)
                               :orgmode
                             else
                               :markup
                             end

      html = Banzai.render(html, context)
      html.html_safe
    rescue Timeout::Error => e
      class_name = name.demodulize
      Gitlab::ErrorTracking.track_exception(e, project_id: context[:project]&.id, class_name: class_name,
        file_name: file_name)

      plain_text_fallback(input)
    rescue GitHub::Markup::CommandError
      plain_text_fallback(input)
    end

    # When the markup renderer fails (errors or times out), we cannot trust
    # its (partial or absent) output, and the raw input is not HTML. Render the
    # input as plain text instead: escape the input, to produce HTML that
    # represents the input as text, then use simple_format to add the <p>/<br>
    # structure. We skip simple_format's own (weak) sanitisation as we guarantee
    # safety when escaping the input text.
    def self.plain_text_fallback(input)
      ActionController::Base.helpers.simple_format(CGI.escapeHTML(input), {}, sanitize: false)
    end
  end
end
