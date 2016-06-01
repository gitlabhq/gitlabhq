module Banzai
  module Filter
    # HTML filter that removes references to records that the current user does
    # not have permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class RedactorFilter < HTML::Pipeline::Filter
      def call
        nodes = Querying.css(doc, 'a.gfm[data-reference-type]')
        visible = nodes_visible_to_user(nodes)

        nodes.each do |node|
          unless visible.include?(node)
            # The reference should be replaced by the original text,
            # which is not always the same as the rendered text.
            text = node.attr('data-original') || node.text
            node.replace(text)
          end
        end

        doc
      end

      private

      def nodes_visible_to_user(nodes)
        per_type = Hash.new { |h, k| h[k] = [] }
        visible = Set.new

        nodes.each do |node|
          per_type[node.attr('data-reference-type')] << node
        end

        per_type.each do |type, nodes|
          parser = Banzai::ReferenceParser[type].new(project, current_user)

          visible.merge(parser.nodes_visible_to_user(current_user, nodes))
        end

        visible
      end

      def current_user
        context[:current_user]
      end

      def project
        context[:project]
      end
    end
  end
end
