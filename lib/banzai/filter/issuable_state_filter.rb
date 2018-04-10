module Banzai
  module Filter
    # HTML filter that appends state information to issuable links.
    # Runs as a post-process filter as issuable state might change whilst
    # Markdown is in the cache.
    #
    # This filter supports cross-project references.
    class IssuableStateFilter < HTML::Pipeline::Filter
      VISIBLE_STATES = %w(closed merged).freeze

      def call
        return doc unless context[:issuable_state_filter_enabled]

        extractor = Banzai::IssuableExtractor.new(project, current_user)
        issuables = extractor.extract([doc])

        issuables.each do |node, issuable|
          next if !can_read_cross_project? && issuable.project != project

          if VISIBLE_STATES.include?(issuable.state) && issuable_reference?(node.inner_html, issuable)
            node.content += " (#{issuable.state})"
          end
        end

        doc
      end

      private

      def issuable_reference?(text, issuable)
        text == issuable.reference_link_text(project || group)
      end

      def can_read_cross_project?
        Ability.allowed?(current_user, :read_cross_project)
      end

      def current_user
        context[:current_user]
      end

      def project
        context[:project]
      end

      def group
        context[:group]
      end
    end
  end
end
