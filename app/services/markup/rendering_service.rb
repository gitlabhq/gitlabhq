# frozen_string_literal: true

module Markup
  class RenderingService
    def initialize(text, file_name: nil, context: {}, postprocess_context: {})
      @text = text
      @file_name = file_name
      @context = context
      @postprocess_context = postprocess_context
    end

    def execute
      return '' unless text.present?
      return context.delete(:rendered) if context.has_key?(:rendered)

      html = markup_unsafe

      return '' unless html.present?

      postprocess_context ? postprocess(html) : html
    end

    private

    def markup_unsafe
      return markdown_unsafe unless file_name

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

    def markdown_unsafe
      Banzai.render(text, context)
    end

    def asciidoc_unsafe
      Gitlab::Asciidoc.render(text, context)
    end

    def plain_unsafe
      ActionController::Base.helpers.content_tag :pre, class: 'plain-readme' do
        text
      end
    end

    def other_markup_unsafe
      Gitlab::OtherMarkup.render(file_name, text, context)
    rescue GitHub::Markup::CommandError
      ActionController::Base.helpers.simple_format(text)
    end

    def postprocess(html)
      Banzai.post_process(html, context.reverse_merge(postprocess_context))
    end

    attr_reader :text, :file_name, :context, :postprocess_context
  end
end
