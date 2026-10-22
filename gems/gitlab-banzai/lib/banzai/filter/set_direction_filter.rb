# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that sets dir="auto" for RTL languages support
    class SetDirectionFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        # select these elements just on top level of the document
        doc.xpath('p|h1|h2|h3|h4|h5|h6|ol|ul[not(@class="section-nav")]|blockquote|table').each do |el|
          el['dir'] = 'auto'
        end

        doc
      end
    end
  end
end
