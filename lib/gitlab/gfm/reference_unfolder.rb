module Gitlab
  module Gfm
    ##
    # Class that unfolds local references in text.
    #
    # The initializer takes text in Markdown and project this text is valid
    # in context of.
    #
    # `unfold` method tries to find all local references and unfold each of
    # those local references to cross reference format.
    #
    # Examples:
    #
    # 'Hello, this issue is related to #123 and
    #  other issues labeled with ~"label"', will be converted to:
    #
    # 'Hello, this issue is related to gitlab-org/gitlab-ce#123 and
    #  other issue labeled with gitlab-org/gitlab-ce~"label"'.
    #
    # It does respect markdown lexical rules, so text in code block will not be
    # replaced, see another example:
    #
    # 'Merge request for issue #1234, see also link:
    #  http://gitlab.com/some/link/#1234, and code `puts #1234`' =>
    #
    # 'Merge request for issue gitlab-org/gitlab-ce#1234, se also link:
    #  http://gitlab.com/some/link/#1234, and code `puts #1234`'
    #
    class ReferenceUnfolder
      def initialize(text, project)
        @text = text
        @project = project
        @original = markdown(text)
      end

      def unfold(from_project)
        return @text unless @text =~ references_pattern

        unfolded = @text.gsub(references_pattern) do |reference|
          unfold_reference(reference, Regexp.last_match, from_project)
        end

        unless substitution_valid?(unfolded)
          raise StandardError, 'Invalid references unfolding!'
        end

        unfolded
      end

      private

      def unfold_reference(reference, match, from_project)
        before = @text[0...match.begin(0)]
        after = @text[match.end(0)...@text.length]
        referable = find_referable(reference)

        return reference unless referable
        cross_reference = referable.to_reference(from_project)
        new_text = before + cross_reference + after

        substitution_valid?(new_text) ? cross_reference : reference
      end

      def references_pattern
        return @pattern if @pattern

        patterns = Gitlab::ReferenceExtractor::REFERABLES.map do |ref|
          ref.to_s.classify.constantize.try(:reference_pattern)
        end

        @pattern = Regexp.union(patterns.compact)
      end

      def referables
        return @referables if @referables

        extractor = Gitlab::ReferenceExtractor.new(@project)
        extractor.analyze(@text)
        @referables = extractor.all
      end

      def find_referable(reference)
        referables.find { |ref| ref.to_reference == reference }
      end

      def substitution_valid?(substituted)
        @original == markdown(substituted)
      end

      def markdown(text)
        Banzai.render(text, project: @project, no_original_data: true)
      end
    end
  end
end
