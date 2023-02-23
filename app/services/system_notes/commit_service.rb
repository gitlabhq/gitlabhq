# frozen_string_literal: true

module SystemNotes
  class CommitService < ::SystemNotes::BaseService
    NEW_COMMIT_DISPLAY_LIMIT = 10

    # Called when commits are added to a merge request
    #
    # new_commits      - Array of Commits added since last push
    # existing_commits - Array of Commits added in a previous push
    # oldrev           - Optional String SHA of a previous Commit
    #
    # See new_commit_summary and existing_commit_summary.
    #
    # Returns the created Note object
    def add_commits(new_commits, existing_commits = [], oldrev = nil)
      total_count  = new_commits.length + existing_commits.length
      commits_text = "#{total_count} commit".pluralize(total_count)

      text_parts = ["added #{commits_text}"]
      text_parts << commits_list(noteable, new_commits, existing_commits, oldrev)
      text_parts << "[Compare with previous version](#{diff_comparison_path(noteable, project, oldrev)})"

      body = text_parts.join("\n\n")

      create_note(NoteSummary.new(noteable, project, author, body, action: 'commit', commit_count: total_count))
    end

    # Called when a commit was tagged
    #
    # tag_name  - The created tag name
    #
    # Returns the created Note object
    def tag_commit(tag_name)
      link = url_helpers.project_tag_path(project, id: tag_name)
      body = "tagged commit #{noteable.sha} to [`#{tag_name}`](#{link})"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'tag'))
    end

    private

    # Build an Array of lines detailing each commit added in a merge request
    #
    # new_commits - Array of new Commit objects
    #
    # Returns an Array of Strings
    def new_commits_list(new_commits)
      new_commits.collect do |commit|
        content_tag('li', "#{commit.short_id} - #{commit.title}")
      end
    end

    # Builds an Array of lines describing each commit and truncate them based on the limit
    # to avoid creating a note with a large number of commits.
    #
    # commits - Array of Commit objects
    #
    # Returns an Array of Strings
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def new_commit_summary(commits, start_rev)
      if commits.size > NEW_COMMIT_DISPLAY_LIMIT
        no_of_commits_to_truncate = commits.size - NEW_COMMIT_DISPLAY_LIMIT
        commits_to_truncate = commits.take(no_of_commits_to_truncate)
        remaining_commits = commits.drop(no_of_commits_to_truncate)

        [truncated_new_commits(commits_to_truncate, start_rev)] + new_commits_list(remaining_commits)
      else
        new_commits_list(commits)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Builds a summary line that describes given truncated commits.
    #
    # commits - Array of Commit objects
    # start_rev - String SHA of a Commit that will be used as the starting SHA of the range
    #
    # Returns a String wrapped in 'li' tag.
    def truncated_new_commits(commits, start_rev)
      count = commits.size

      commit_ids = if count == 1
                     commits.first.short_id
                   elsif start_rev && !Gitlab::Git.blank_ref?(start_rev)
                     "#{Commit.truncate_sha(start_rev)}...#{commits.last.short_id}"
                   else
                     # This two-dots notation seems to be not functioning as expected, but we should
                     # fallback to it as start_rev can be empty.
                     #
                     # For more information, please see https://gitlab.com/gitlab-org/gitlab/-/issues/391809
                     "#{commits.first.short_id}..#{commits.last.short_id}"
                   end

      commits_text = "#{count} earlier commit".pluralize(count)

      content_tag('li', "#{commit_ids} - #{commits_text}")
    end

    # Builds a list of existing and new commits according to existing_commits and
    # new_commits methods.
    # Returns a String wrapped in `ul` and `li` tags.
    def commits_list(noteable, new_commits, existing_commits, oldrev)
      existing_commit_summary = existing_commit_summary(noteable, existing_commits, oldrev)
      start_rev = existing_commits.empty? ? oldrev : existing_commits.last.id
      new_commit_summary = new_commit_summary(new_commits, start_rev).join

      content_tag('ul', "#{existing_commit_summary}#{new_commit_summary}".html_safe)
    end

    # Build a single line summarizing existing commits being added in a merge
    # request
    #
    # existing_commits - Array of existing Commit objects
    # oldrev           - Optional String SHA of a previous Commit
    #
    # Examples:
    #
    #   "* ea0f8418...2f4426b7 - 24 commits from branch `master`"
    #
    #   "* ea0f8418..4188f0ea - 15 commits from branch `fork:master`"
    #
    #   "* ea0f8418 - 1 commit from branch `feature`"
    #
    # Returns a newline-terminated String
    def existing_commit_summary(noteable, existing_commits, oldrev = nil)
      return '' if existing_commits.empty?

      count = existing_commits.size

      commit_ids = if count == 1
                     existing_commits.first.short_id
                   elsif oldrev && !Gitlab::Git.blank_ref?(oldrev)
                     "#{Commit.truncate_sha(oldrev)}...#{existing_commits.last.short_id}"
                   else
                     "#{existing_commits.first.short_id}..#{existing_commits.last.short_id}"
                   end

      commits_text = "#{count} commit".pluralize(count)

      branch = noteable.target_branch
      branch = "#{noteable.target_project_namespace}:#{branch}" if noteable.for_fork?

      branch_name = content_tag('code', branch)
      content_tag('li', "#{commit_ids} - #{commits_text} from branch #{branch_name}".html_safe)
    end

    def diff_comparison_path(merge_request, project, oldrev)
      diff_id = merge_request.merge_request_diff.id

      url_helpers.diffs_project_merge_request_path(
        project,
        merge_request,
        diff_id: diff_id,
        start_sha: oldrev
      )
    end
  end
end
