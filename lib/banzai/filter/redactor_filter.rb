require 'html/pipeline/filter'

module Banzai
  module Filter
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class RedactorFilter < HTML::Pipeline::Filter
      def call
        Querying.css(doc, 'a.gfm').each do |node|
          unless user_can_see_reference?(node)
            # The reference should be replaced by the original text,
            # which is not always the same as the rendered text.
            text = node.attr('data-original') || node.text
            node.replace(text)
          end
        end

        doc
      end

      private

      def user_can_see_reference?(node)
        if node.has_attribute?('data-reference-filter')
          reference_type = node.attr('data-reference-filter')
          reference_filter = Banzai::Filter.const_get(reference_type)

          reference_filter.user_can_see_reference?(current_user, node, context)
        else
          true
        end
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
