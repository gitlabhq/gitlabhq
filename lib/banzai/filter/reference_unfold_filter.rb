module Banzai
  module Filter
    ##
    # Filter than unfolds local references.
    #
    # Replaces all local references with project cross reference version
    # in all objects passed to this filter in context.
    #
    # Requires objects array with each element implementing `Referable`.
    #
    class ReferenceUnfoldFilter < ReferenceFilter
      def initialize(*)
        super

        @objects = context[:objects]
        @project = context[:project]

        unless @objects.all? { |object| object.respond_to?(:to_reference) }
          raise StandardError, "No `to_reference` method implemented in one of the objects !"
        end

        unless @project.kind_of?(Project)
          raise StandardError, 'No valid project passed in context!'
        end
      end

      def call
        @objects.each do |object|
          pattern = /#{Regexp.escape(object.to_reference)}/
          replace_text_nodes_matching(pattern) do |content|
            content.gsub(pattern, object.to_reference(@project))
          end
        end

        doc
      end

      private

      def validate
        needs :project
        needs :objects
      end
    end
  end
end
