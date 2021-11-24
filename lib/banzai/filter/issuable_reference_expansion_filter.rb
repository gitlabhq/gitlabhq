# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that appends extra information to issuable links.
    # Runs as a post-process filter as issuable might change while
    # Markdown is in the cache.
    #
    # This filter supports cross-project references.
    class IssuableReferenceExpansionFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      VISIBLE_STATES = %w(closed merged).freeze

      def call
        return doc unless context[:issuable_reference_expansion_enabled]

        context = RenderContext.new(project, current_user)
        extractor = Banzai::IssuableExtractor.new(context)
        issuables = extractor.extract([doc])

        issuables.each do |node, issuable|
          next if !can_read_cross_project? && cross_referenced?(issuable)
          next unless should_expand?(node, issuable)

          case node.attr('data-reference-format')
          when '+'
            expand_reference_with_title_and_state(node, issuable)
          else
            expand_reference_with_state(node, issuable)
          end
        end

        doc
      end

      private

      # Example: Issue Title (#123 - closed)
      def expand_reference_with_title_and_state(node, issuable)
        node.content = "#{issuable.title.truncate(50)} (#{node.content}"
        node.content += " - #{issuable_state_text(issuable)}" if VISIBLE_STATES.include?(issuable.state)
        node.content += ')'
      end

      # Example: #123 (closed)
      def expand_reference_with_state(node, issuable)
        node.content += " (#{issuable_state_text(issuable)})"
      end

      def issuable_state_text(issuable)
        moved_issue?(issuable) ? s_("IssuableStatus|moved") : issuable.state
      end

      def moved_issue?(issuable)
        issuable.instance_of?(Issue) && issuable.moved?
      end

      def should_expand?(node, issuable)
        # We add this extra check to avoid unescaping HTML and generating reference link text for every reference
        return unless node.attr('data-reference-format').present? || VISIBLE_STATES.include?(issuable.state)

        CGI.unescapeHTML(node.inner_html) == issuable.reference_link_text(project || group)
      end

      def cross_referenced?(issuable)
        return true if issuable.project != project
        return true if issuable.respond_to?(:group) && issuable.group != group

        false
      end

      def can_read_cross_project?
        strong_memoize(:can_read_cross_project) do
          Ability.allowed?(current_user, :read_cross_project)
        end
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
