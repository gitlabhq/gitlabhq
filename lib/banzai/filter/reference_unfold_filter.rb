require 'html/pipeline/filter'

module Banzai
  module Filter
    ##
    # Filter than unfolds local references.
    #
    #
    class ReferenceUnfoldFilter < HTML::Pipeline::Filter
      def initialize(*)
        super

        unless result[:references].is_a?(Hash)
          raise StandardError, 'References not processed!'
        end

        @text = context[:text].dup
        @new_project = context[:new_project]
        @referables = result[:references].values.flatten
      end

      def call
        @referables.each do |referable|
          pattern = /#{Regexp.escape(referable.to_reference)}/
          @text.gsub!(pattern, referable.to_reference(@new_project))
        end

        @text
      end

      private

      def validate
        needs :project
        needs :new_project
        needs :text
      end
    end
  end
end
