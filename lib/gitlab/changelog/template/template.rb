# frozen_string_literal: true

module Gitlab
  module Changelog
    module Template
      # A wrapper around an ERB template user for rendering changelogs.
      class Template
        TemplateError = Class.new(StandardError)

        def initialize(erb)
          # Don't change the trim mode, as this may require changes to the
          # regular expressions used to turn the template syntax into ERB
          # tags.
          @erb = ERB.new(erb, trim_mode: '-')
        end

        def render(data)
          context = Context.new(data).get_binding

          # ERB produces a SyntaxError when processing templates, as it
          # internally uses eval() for this.
          @erb.result(context)
        rescue SyntaxError
          raise TemplateError.new("The template's syntax is invalid")
        end
      end
    end
  end
end
