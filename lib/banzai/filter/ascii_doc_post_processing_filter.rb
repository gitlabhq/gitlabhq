# frozen_string_literal: true

module Banzai
  module Filter
    class AsciiDocPostProcessingFilter < HTML::Pipeline::Filter
      def call
        doc.search('[data-math-style]').each do |node|
          node.set_attribute('class', 'code math js-render-math')
        end

        doc.search('[data-mermaid-style]').each do |node|
          node.set_attribute('class', 'js-render-mermaid')
        end
        doc
      end
    end
  end
end
