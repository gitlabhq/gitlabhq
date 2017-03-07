module Issues
  class BuildService < Issues::BaseService
    def execute
      @issue = project.issues.new(issue_params)
    end

    def issue_params_with_info_from_merge_request
      return {} unless merge_request_for_resolving_discussions

      { title: title_from_merge_request, description: description_from_merge_request }
    end

    def title_from_merge_request
      "Follow-up from \"#{merge_request_for_resolving_discussions.title}\""
    end

    def description_from_merge_request
      if merge_request_for_resolving_discussions.resolvable_discussions.empty?
        return "There are no unresolved discussions. "\
               "Review the conversation in #{merge_request_for_resolving_discussions.to_reference}"
      end

      description = "The following discussions from #{merge_request_for_resolving_discussions.to_reference} should be addressed:"
      [description, *items_for_discussions].join("\n\n")
    end

    def items_for_discussions
      merge_request_for_resolving_discussions.resolvable_discussions.map { |discussion| item_for_discussion(discussion) }
    end

    def item_for_discussion(discussion)
      first_note = discussion.first_note_to_resolve
      other_note_count = discussion.notes.size - 1
      creation_time = first_note.created_at.to_s(:medium)
      note_url = Gitlab::UrlBuilder.build(first_note)

      discussion_info = "- [ ] #{first_note.author.to_reference} commented in a discussion on [#{creation_time}](#{note_url}): "
      discussion_info << " (+#{other_note_count} #{'comment'.pluralize(other_note_count)})" if other_note_count > 0

      note_without_block_quotes = Banzai::Filter::BlockquoteFenceFilter.new(first_note.note).call
      quote = ">>>\n#{note_without_block_quotes}\n>>>"

      [discussion_info, quote].join("\n\n")
    end

    def issue_params
      @issue_params ||= issue_params_with_info_from_merge_request.merge(whitelisted_issue_params)
    end

    def whitelisted_issue_params
      if can?(current_user, :admin_issue, project)
        params.slice(:title, :description, :milestone_id)
      else
        params.slice(:title, :description)
      end
    end
  end
end
