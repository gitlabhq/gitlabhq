require 'gitlab/markdown'
require 'html/pipeline/filter'

module Gitlab
  module Markdown
    # HTML filter that gathers all referenced records that the current user has
    # permission to view.
    #
    # Expected to be run in its own post-processing pipeline.
    #
    class ReferenceGathererFilter < HTML::Pipeline::Filter
      def initialize(*)
        super

        result[:lazy_references]  ||= Hash.new { |hash, type| hash[type] = [] }
        result[:references]       ||= Hash.new { |hash, type| hash[type] = [] }
      end

      def call
        doc.css('a.gfm').each do |node|
          gather_references(node)
        end

        load_lazy_references

        doc
      end

      private

      def gather_references(node)
        return unless node.has_attribute?('data-reference-filter')

        reference_type = node.attr('data-reference-filter')
        reference_filter = reference_type.constantize

        return unless reference_filter.user_can_reference?(current_user, node, context)

        references = reference_filter.referenced_by(node)
        return unless references

        references.each do |type, values|
          Array.wrap(values).each do |value|
            refs = 
              if value.is_a?(ReferenceFilter::LazyReference)
                result[:lazy_references]
              else
                result[:references]
              end

            refs[type] << value
          end
        end
      end

      # Will load all references of one type using one query.
      def load_lazy_references
        result[:lazy_references].each do |type, refs|
          refs.group_by(&:klass).each do |klass, refs|
            ids = refs.map(&:ids).flatten
            values = klass.find(ids)
            result[:references][type].push(*values)
          end
        end
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
