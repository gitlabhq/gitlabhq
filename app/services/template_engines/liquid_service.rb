# frozen_string_literal: true

module TemplateEngines
  class LiquidService < BaseService
    RenderError = Class.new(StandardError)

    DEFAULT_RENDER_SCORE_LIMIT = 1_000

    def initialize(string)
      @template = Liquid::Template.parse(string)
    end

    def render(context, render_score_limit: DEFAULT_RENDER_SCORE_LIMIT)
      set_limits(render_score_limit)

      @template.render!(context.stringify_keys)
    rescue Liquid::MemoryError => e
      handle_exception(e, string: @string, context: context)

      raise RenderError, _('Memory limit exceeded while rendering template')
    rescue Liquid::Error => e
      handle_exception(e, string: @string, context: context)

      raise RenderError, _('Error rendering query')
    end

    private

    def set_limits(render_score_limit)
      @template.resource_limits.render_score_limit = render_score_limit

      # We can also set assign_score_limit and render_length_limit if required.

      # render_score_limit limits the number of nodes (string, variable, block, tags)
      #   that are allowed in the template.
      # render_length_limit seems to limit the sum of the bytesize of all node blocks.
      # assign_score_limit seems to limit the sum of the bytesize of all capture blocks.
    end

    def handle_exception(exception, extra = {})
      log_error(exception.message)
      Gitlab::ErrorTracking.track_exception(exception, {
        template_string: extra[:string],
        variables: extra[:context]
      })
    end
  end
end
