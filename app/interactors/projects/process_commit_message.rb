module Projects
  class ProcessCommitMessage < Projects::Base
    def perform
      project = context[:project]
      push_commits = context[:push_commits]

      is_default_branch = is_default_branch?(ref)

      push_commits.each do |commit|
        # Close issues if these commits were pushed to the project's default branch and the commit message matches the
        # closing regex. Exclude any mentioned Issues from cross-referencing even if the commits are being pushed to
        # a different branch.
        issues_to_close = commit.closes_issues(project)
        author = commit_user(commit)

        if !issues_to_close.empty? && is_default_branch
          issues_to_close.each do |issue|
            Issues::CloseService.new(project, author, {}).execute(issue, commit)
          end
        end

        # Create cross-reference notes for any other references. Omit any issues that were referenced in an
        # issue-closing phrase, or have already been mentioned from this commit (probably from this commit
        # being pushed to a different branch).
        refs = commit.references(project) - issues_to_close
        refs.reject! { |r| commit.has_mentioned?(r) }
        refs.each do |r|
          Note.create_cross_reference_note(r, commit, author, project)
        end
      end
    end

    def rollback
      # context.delete(:)
    end

    private

    def is_default_branch? ref
      ref == "refs/heads/#{project.default_branch}"
    end
  end
end
