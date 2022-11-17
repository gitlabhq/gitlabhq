# frozen_string_literal: true

module Markup
  class RenderingService
    include ActionView::Helpers::TextHelper

    # Let's increase the render timeout
    # For a smaller one, a test that renders the blob content statically fails
    # We can consider removing this custom timeout when markup_rendering_timeout FF is removed:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/365358
    RENDER_TIMEOUT = 5.seconds

    def initialize(text, file_name: nil, context: {}, postprocess_context: {})
      @text = text
      @file_name = file_name
      @context = context
      @postprocess_context = postprocess_context
    end

    def execute
      return '' unless text.present?
      return context.delete(:rendered) if context.has_key?(:rendered)

      html = file_name ? markup_unsafe : markdown_unsafe

      return '' unless html.present?

      postprocess_context ? postprocess(html) : html
    end

    private

    def markup_unsafe
      markup = proc do
        if Gitlab::MarkupHelper.gitlab_markdown?(file_name)
          markdown_unsafe
        elsif Gitlab::MarkupHelper.asciidoc?(file_name)
          asciidoc_unsafe
        elsif Gitlab::MarkupHelper.plain?(file_name)
          plain_unsafe
        else
          other_markup_unsafe
        end
      end

      if Feature.enabled?(:markup_rendering_timeout, context[:project])
        Gitlab::RenderTimeout.timeout(foreground: RENDER_TIMEOUT, &markup)
      else
        markup.call
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, project_id: context[:project]&.id, file_name: file_name)

      simple_format(text)
    end

    def markdown_unsafe
      Banzai.render(text, context)
    end

    def asciidoc_unsafe
      Gitlab::Asciidoc.render(text, context)
    end

    def plain_unsafe
      "<pre class=\"plain-readme\">#{text}</pre>"
    end

    def other_markup_unsafe
      Gitlab::OtherMarkup.render(file_name, text, context)
    end

    def postprocess(html)
      Banzai.post_process(html, context.reverse_merge(postprocess_context))
    end

    attr_reader :text, :file_name, :context, :postprocess_context
  end
end
