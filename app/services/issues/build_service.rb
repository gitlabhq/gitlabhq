# frozen_string_literal: true

module Issues
  class BuildService < Issues::BaseService
    include ResolveDiscussions

    def execute
      filter_resolve_discussion_params
      @issue = project.issues.new(issue_params).tap do |issue|
        ensure_milestone_available(issue)
      end
    end

    def issue_params_with_info_from_discussions
      return {} unless merge_request_to_resolve_discussions_of

      { title: title_from_merge_request, description: description_for_discussions }
    end

    def title_from_merge_request
      "Follow-up from \"#{merge_request_to_resolve_discussions_of.title}\""
    end

    def description_for_discussions
      if discussions_to_resolve.empty?
        return "There are no unresolved discussions. "\
               "Review the conversation in #{merge_request_to_resolve_discussions_of.to_reference}"
      end

      description = "The following #{'discussion'.pluralize(discussions_to_resolve.size)} "\
                    "from #{merge_request_to_resolve_discussions_of.to_reference} "\
                    "should be addressed:"

      [description, *items_for_discussions].join("\n\n")
    end

    def items_for_discussions
      discussions_to_resolve.map { |discussion| item_for_discussion(discussion) }
    end

    def item_for_discussion(discussion)
      first_note_to_resolve = discussion.first_note_to_resolve || discussion.first_note

      is_very_first_note = first_note_to_resolve == discussion.first_note
      action = is_very_first_note ? "started" : "commented on"

      note_url = Gitlab::UrlBuilder.build(first_note_to_resolve)

      other_note_count = discussion.notes.size - 1

      discussion_info = ["- [ ] #{first_note_to_resolve.author.to_reference} #{action} a [discussion](#{note_url}): "]
      discussion_info << "(+#{other_note_count} #{'comment'.pluralize(other_note_count)})" if other_note_count > 0

      note_without_block_quotes = Banzai::Filter::BlockquoteFenceFilter.new(first_note_to_resolve.note).call
      spaces = ' ' * 4
      quote = note_without_block_quotes.lines.map { |line| "#{spaces}> #{line}" }.join

      [discussion_info.join(' '), quote].join("\n\n")
    end

    def issue_params
      @issue_params ||= build_issue_params
    end

    private

    def allowed_issue_params
      allowed_params = [
        :title,
        :description,
        :confidential
      ]

      allowed_params << :milestone_id if can?(current_user, :admin_issue, project)
      allowed_params << :issue_type if issue_type_allowed?(project)

      params.slice(*allowed_params)
    end

    def build_issue_params
      { author: current_user }
        .merge(issue_params_with_info_from_discussions)
        .merge(allowed_issue_params)
    end
  end
end

Issues::BuildService.prepend_mod_with('Issues::BuildService')
