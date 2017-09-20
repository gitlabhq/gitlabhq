module Gitlab
  module Gfm
    ##
    # Class that unfolds local references in text.
    #
    # The initializer takes text in Markdown and project this text is valid
    # in context of.
    #
    # `unfold` method tries to find all local references and unfold each of
    # those local references to cross reference format, assuming that the
    # argument passed to this method is a project that references will be
    # viewed from (see `Referable#to_reference method).
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
    class ReferenceRewriter
      RewriteError = Class.new(StandardError)

      def initialize(text, source_project, current_user)
        @text = text
        @source_project = source_project
        @current_user = current_user
        @original_html = markdown(text)
        @pattern = Gitlab::ReferenceExtractor.references_pattern
      end

      def rewrite(target_project)
        return @text unless needs_rewrite?

        @text.gsub(@pattern) do |reference|
          unfold_reference(reference, Regexp.last_match, target_project)
        end
      end

      def needs_rewrite?
        @text =~ @pattern
      end

      private

      def unfold_reference(reference, match, target_project)
        before = @text[0...match.begin(0)]
        after = @text[match.end(0)..-1]

        referable = find_referable(reference)
        return reference unless referable

        cross_reference = build_cross_reference(referable, target_project)
        return reference if reference == cross_reference

        if cross_reference.nil?
          raise RewriteError, "Unspecified reference detected for #{referable.class.name}"
        end

        new_text = before + cross_reference + after
        substitution_valid?(new_text) ? cross_reference : reference
      end

      def find_referable(reference)
        extractor = Gitlab::ReferenceExtractor.new(@source_project,
                                                   @current_user)
        extractor.analyze(reference)
        extractor.all.first
      end

      def build_cross_reference(referable, target_project)
        if referable.respond_to?(:project)
          referable.to_reference(target_project)
        else
          referable.to_reference(@source_project, target_project: target_project)
        end
      end

      def substitution_valid?(substituted)
        @original_html == markdown(substituted)
      end

      def markdown(text)
        Banzai.render(text, project: @source_project, no_original_data: true)
      end
    end
  end
end
