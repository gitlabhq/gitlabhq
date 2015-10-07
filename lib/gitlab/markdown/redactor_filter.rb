require 'gitlab/markdown'
require 'html/pipeline/filter'

module Gitlab
  module Markdown
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class RedactorFilter < HTML::Pipeline::Filter
      def call
        doc.css('a.gfm').each do |node|
          unless user_can_reference?(node)
            node.replace(node.text)
          end
        end

        doc
      end

      private

      def user_can_reference?(node)
        if node.has_attribute?('data-reference-filter')
          reference_type = node.attr('data-reference-filter')
          reference_filter = reference_type.constantize

          reference_filter.user_can_reference?(current_user, node, context)
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
