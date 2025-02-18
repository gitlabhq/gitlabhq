# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that appends extra information to issuable links.
    # Runs as a post-process filter as issuable might change while
    # Markdown is in the cache.
    #
    # This filter supports cross-project references.
    class IssuableReferenceExpansionFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Gitlab::Utils::StrongMemoize

      NUMBER_OF_SUMMARY_ASSIGNEES = 2
      VISIBLE_STATES = %w[closed merged].freeze
      EXTENDED_FORMAT_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath('a[data-reference-format="+s"]')

      def call
        return doc unless context[:issuable_reference_expansion_enabled]

        options = { extended_preload: doc.xpath(EXTENDED_FORMAT_XPATH).present? }
        extractor_context = RenderContext.new(project, current_user, options: options)

        extractor = Banzai::IssuableExtractor.new(extractor_context)
        issuables = extractor.extract([doc])

        issuables.each do |node, issuable|
          next if !can_read_cross_project? && cross_referenced?(issuable)
          next unless should_expand?(node, issuable)

          case node.attr('data-reference-format')
          when '+'
            expand_reference_with_title_and_state(node, issuable)
          when '+s'
            expand_reference_with_title_and_state(node, issuable)
            expand_reference_with_summary(node, issuable)
          else
            expand_reference_with_state(node, issuable)
          end
        end

        doc
      end

      private

      # Example: Issue Title (#123 - closed)
      def expand_reference_with_title_and_state(node, issuable)
        node.content = "#{expand_emoji(issuable.title).truncate(50)} (#{node.content}"
        node.content += " - #{issuable_state_text(issuable)}" if VISIBLE_STATES.include?(issuable.state)
        node.content += ')'
      end

      # rubocop:disable Style/AsciiComments
      # Example: Issue Title (#123 - closed) assignee name 1, assignee name 2+ • v15.9 • On track
      def expand_reference_with_summary(node, issuable)
        summary = []

        summary << assignees_text(issuable) if issuable.supports_assignee?
        summary << milestone_text(issuable.milestone) if issuable.supports_milestone?
        summary << health_status_text(issuable.health_status) if issuable.supports_health_status?

        node.content = [node.content, *summary].compact_blank.join(' • ')
      end
      # rubocop:enable Style/AsciiComments

      # Example: #123 (closed)
      def expand_reference_with_state(node, issuable)
        node.content += " (#{issuable_state_text(issuable)})"
      end

      def assignees_text(issuable)
        assignee_names = issuable.assignees.first(NUMBER_OF_SUMMARY_ASSIGNEES + 1).map(&:sanitize_name)

        return _('Unassigned') if assignee_names.empty?

        "#{assignee_names.first(NUMBER_OF_SUMMARY_ASSIGNEES).to_sentence(two_words_connector: ', ')}" \
          "#{assignee_names.size > NUMBER_OF_SUMMARY_ASSIGNEES ? '+' : ''}"
      end

      def milestone_text(milestone)
        milestone&.title
      end

      def health_status_text(health_status)
        health_status&.humanize
      end

      def issuable_state_text(issuable)
        moved_issue?(issuable) ? s_("IssuableStatus|moved") : issuable.state
      end

      def moved_issue?(issuable)
        issuable.is_a?(Issue) && issuable.moved?
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

      def expand_emoji(string)
        string.gsub(/(?<!\w):(\w+):(?!\w)/) do |match|
          emoji_codepoint = TanukiEmoji.find_by_alpha_code(::Regexp.last_match(1))&.codepoints
          !emoji_codepoint.nil? ? emoji_codepoint : match
        end
      end
    end
  end
end

Banzai::Filter::IssuableReferenceExpansionFilter.prepend_mod
