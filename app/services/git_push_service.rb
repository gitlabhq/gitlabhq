class GitPushService
  attr_accessor :project, :user, :push_data, :push_commits
  include Gitlab::CurrentSettings
  include Gitlab::Access

  # This method will be called after each git update
  # and only if the provided user and project is present in GitLab.
  #
  # All callbacks for post receive action should be placed here.
  #
  # Next, this method:
  #  1. Creates the push event
  #  2. Updates merge requests
  #  3. Recognizes cross-references from commit messages
  #  4. Executes the project's web hooks
  #  5. Executes the project's services
  #
  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user

    project.repository.expire_cache

    if push_remove_branch?(ref, newrev)
      @push_commits = []
    elsif push_to_new_branch?(ref, oldrev)
      # Re-find the pushed commits.
      if is_default_branch?(ref)
        # Initial push to the default branch. Take the full history of that branch as "newly pushed".
        @push_commits = project.repository.commits(newrev)

        # Ensure HEAD points to the default branch in case it is not master
        branch_name = Gitlab::Git.ref_name(ref)
        project.change_head(branch_name)

        # Set protection on the default branch if configured
        if (current_application_settings.default_branch_protection != PROTECTION_NONE)
          developers_can_push = current_application_settings.default_branch_protection == PROTECTION_DEV_CAN_PUSH ? true : false
          project.protected_branches.create({ name: project.default_branch, developers_can_push: developers_can_push })
        end
      else
        # Use the pushed commits that aren't reachable by the default branch
        # as a heuristic. This may include more commits than are actually pushed, but
        # that shouldn't matter because we check for existing cross-references later.
        @push_commits = project.repository.commits_between(project.default_branch, newrev)

        # don't process commits for the initial push to the default branch
        process_commit_messages(ref)
      end
    elsif push_to_existing_branch?(ref, oldrev)
      # Collect data for this git push
      @push_commits = project.repository.commits_between(oldrev, newrev)
      project.update_merge_requests(oldrev, newrev, ref, @user)
      process_commit_messages(ref)
    end

    @push_data = build_push_data(oldrev, newrev, ref)

    EventCreateService.new.push(project, user, @push_data)
    project.execute_hooks(@push_data.dup, :push_hooks)
    project.execute_services(@push_data.dup, :push_hooks)
    ProjectCacheWorker.perform_async(project.id)
  end

  protected

  # Extract any GFM references from the pushed commit messages. If the configured issue-closing regex is matched,
  # close the referenced Issue. Create cross-reference Notes corresponding to any other referenced Mentionables.
  def process_commit_messages(ref)
    is_default_branch = is_default_branch?(ref)

    @push_commits.each do |commit|
      # Close issues if these commits were pushed to the project's default branch and the commit message matches the
      # closing regex. Exclude any mentioned Issues from cross-referencing even if the commits are being pushed to
      # a different branch.
      issues_to_close = commit.closes_issues(user)

      # Load commit author only if needed.
      # For push with 1k commits it prevents 900+ requests in database
      author = nil

      # Keep track of the issues that will be actually closed because they are on a default branch.
      # Hence, when creating cross-reference notes, the not-closed issues (on non-default branches)
      # will also have cross-reference.
      actually_closed_issues = []

      if issues_to_close.present? && is_default_branch
        author ||= commit_user(commit)
        actually_closed_issues = issues_to_close
        issues_to_close.each do |issue|
          Issues::CloseService.new(project, author, {}).execute(issue, commit)
        end
      end

      if project.default_issues_tracker?
        create_cross_reference_notes(commit, actually_closed_issues)
      end
    end
  end

  def create_cross_reference_notes(commit, issues_to_close)
    # Create cross-reference notes for any other references than those given in issues_to_close.
    # Omit any issues that were referenced in an issue-closing phrase, or have already been
    # mentioned from this commit (probably from this commit being pushed to a different branch).
    refs = commit.references(project, user) - issues_to_close
    refs.reject! { |r| commit.has_mentioned?(r) }

    if refs.present?
      author ||= commit_user(commit)

      refs.each do |r|
        SystemNoteService.cross_reference(r, commit, author)
      end
    end
  end

  def build_push_data(oldrev, newrev, ref)
    Gitlab::PushDataBuilder.
      build(project, user, oldrev, newrev, ref, push_commits)
  end

  def push_to_existing_branch?(ref, oldrev)
    # Return if this is not a push to a branch (e.g. new commits)
    Gitlab::Git.branch_ref?(ref) && !Gitlab::Git.blank_ref?(oldrev)
  end

  def push_to_new_branch?(ref, oldrev)
    Gitlab::Git.branch_ref?(ref) && Gitlab::Git.blank_ref?(oldrev)
  end

  def push_remove_branch?(ref, newrev)
    Gitlab::Git.branch_ref?(ref) && Gitlab::Git.blank_ref?(newrev)
  end

  def push_to_branch?(ref)
    Gitlab::Git.branch_ref?(ref)
  end

  def is_default_branch?(ref)
    Gitlab::Git.branch_ref?(ref) &&
      (Gitlab::Git.ref_name(ref) == project.default_branch || project.default_branch.nil?)
  end

  def commit_user(commit)
    commit.author || user
  end
end
