module Gitlab
  module Gfm
    ##
    # Class than unfolds local references in text.
    #
    #
    class ReferenceUnfolder
      def initialize(text, project)
        @text = text
        @project = project
      end

      def unfold(from_project)
        referables.each_with_object(@text.dup) do |referable, text|
          next unless referable.respond_to?(:to_reference)

          pattern = /#{Regexp.escape(referable.to_reference)}/
          text.gsub!(pattern, referable.to_reference(from_project))
        end
      end

      private

      def referables
        extractor = Gitlab::ReferenceExtractor.new(@project)
        extractor.analyze(@text)
        extractor.all
      end
    end
  end
end
