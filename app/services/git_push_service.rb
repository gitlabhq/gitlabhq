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
  #  2. Ensures that the project satellite exists
  #  3. Updates merge requests
  #  4. Recognizes cross-references from commit messages
  #  5. Executes the project's web hooks
  #  6. Executes the project's services
  #
  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user

    project.ensure_satellite_exists
    project.repository.expire_cache
    project.update_repository_size

    if push_to_branch?(ref)
      if push_remove_branch?(ref, newrev)
        @push_commits = []
      elsif push_to_new_branch?(ref, oldrev)
        # Re-find the pushed commits.
        if is_default_branch?(ref)
          # Initial push to the default branch. Take the full history of that branch as "newly pushed".
          @push_commits = project.repository.commits(newrev)

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
        end
        process_commit_messages(ref)
      elsif push_to_existing_branch?(ref, oldrev)
        # Collect data for this git push
        @push_commits = project.repository.commits_between(oldrev, newrev)
        project.update_merge_requests(oldrev, newrev, ref, @user)
        process_commit_messages(ref)
      end

      @push_data = post_receive_data(oldrev, newrev, ref)
      EventCreateService.new.push(project, user, @push_data)
      project.execute_hooks(@push_data.dup, :push_hooks)
      project.execute_services(@push_data.dup)
    end
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
      issues_to_close = commit.closes_issues(project)

      # Load commit author only if needed.
      # For push with 1k commits it prevents 900+ requests in database
      author = nil

      if issues_to_close.present? && is_default_branch
        author ||= commit_user(commit)

        issues_to_close.each do |issue|
          Issues::CloseService.new(project, author, {}).execute(issue, commit)
        end
      end

      # Create cross-reference notes for any other references. Omit any issues that were referenced in an
      # issue-closing phrase, or have already been mentioned from this commit (probably from this commit
      # being pushed to a different branch).
      refs = commit.references(project) - issues_to_close
      refs.reject! { |r| commit.has_mentioned?(r) }

      if refs.present?
        author ||= commit_user(commit)

        refs.each do |r|
          Note.create_cross_reference_note(r, commit, author, project)
        end
      end
    end
  end

  def post_receive_data(oldrev, newrev, ref)
    Gitlab::PushDataBuilder.
      build(project, user, oldrev, newrev, ref, push_commits)
  end

  def push_to_existing_branch?(ref, oldrev)
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    ref_parts[1].include?('heads') && oldrev != Gitlab::Git::BLANK_SHA
  end

  def push_to_new_branch?(ref, oldrev)
    ref_parts = ref.split('/')

    ref_parts[1].include?('heads') && oldrev == Gitlab::Git::BLANK_SHA
  end

  def push_remove_branch?(ref, newrev)
    ref_parts = ref.split('/')

    ref_parts[1].include?('heads') && newrev == Gitlab::Git::BLANK_SHA
  end

  def push_to_branch?(ref)
    ref.include?('refs/heads')
  end

  def is_default_branch?(ref)
    ref == "refs/heads/#{project.default_branch}"
  end

  def commit_user(commit)
    User.find_for_commit(commit.author_email, commit.author_name) || user
  end
end
