require 'html/pipeline/filter'

module Banzai
  module Filter
    # HTML filter that gathers all referenced records that the current user has
    # permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class ReferenceGathererFilter < HTML::Pipeline::Filter
      def initialize(*)
        super

        result[:references] ||= Hash.new { |hash, type| hash[type] = [] }
      end

      def call
        Querying.css(doc, 'a.gfm').each do |node|
          gather_references(node)
        end

        load_lazy_references unless ReferenceExtractor.lazy?

        doc
      end

      private

      def gather_references(node)
        return unless node.has_attribute?('data-reference-filter')

        reference_type = node.attr('data-reference-filter')
        reference_filter = Banzai::Filter.const_get(reference_type)

        return if context[:reference_filter] && reference_filter != context[:reference_filter]

        return if author && !reference_filter.user_can_reference?(author, node, context)

        return unless reference_filter.user_can_see_reference?(current_user, node, context)

        references = reference_filter.referenced_by(node)
        return unless references

        references.each do |type, values|
          Array.wrap(values).each do |value|
            result[:references][type] << value
          end
        end
      end

      def load_lazy_references
        refs = result[:references]
        refs.each do |type, values|
          refs[type] = ReferenceExtractor.lazily(values)
        end
      end

      def current_user
        context[:current_user]
      end

      def author
        context[:author]
      end
    end
  end
end
