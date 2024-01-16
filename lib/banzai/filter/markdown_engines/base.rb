# frozen_string_literal: true

module Banzai
  module Filter
    module MarkdownEngines
      class Base
        attr_reader :context

        def initialize(context)
          @context = context || {}
        end

        def render(text)
          raise NotImplementedError
        end

        private

        def sourcepos_disabled?
          context[:no_sourcepos]
        end
      end
    end
  end
end
