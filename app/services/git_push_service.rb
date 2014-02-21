class GitPushService
  attr_accessor :project, :user, :push_data, :push_commits

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

    # Collect data for this git push
    @push_commits = project.repository.commits_between(oldrev, newrev)
    @push_data = post_receive_data(oldrev, newrev, ref)

    create_push_event

    project.ensure_satellite_exists
    project.repository.expire_cache

    if push_to_existing_branch?(ref, oldrev)
      project.update_merge_requests(oldrev, newrev, ref, @user)
      process_commit_messages(ref)
    end

    if push_to_branch?(ref)
      project.execute_hooks(@push_data.dup, :push_hooks)
      project.execute_services(@push_data.dup)
    end

    if push_to_new_branch?(ref, oldrev)
      # Re-find the pushed commits.
      if is_default_branch?(ref)
        # Initial push to the default branch. Take the full history of that branch as "newly pushed".
        @push_commits = project.repository.commits(newrev)
      else
        # Use the pushed commits that aren't reachable by the default branch
        # as a heuristic. This may include more commits than are actually pushed, but
        # that shouldn't matter because we check for existing cross-references later.
        @push_commits = project.repository.commits_between(project.default_branch, newrev)
      end

      process_commit_messages(ref)
    end
  end

  # This method provide a sample data
  # generated with post_receive_data method
  # for given project
  #
  def sample_data(project, user)
    @project, @user = project, user
    @push_commits = project.repository.commits(project.default_branch, nil, 3)
    post_receive_data(@push_commits.last.id, @push_commits.first.id, "refs/heads/#{project.default_branch}")
  end

  protected

  def create_push_event
    Event.create!(
      project: project,
      action: Event::PUSHED,
      data: push_data,
      author_id: push_data[:user_id]
    )
  end

  # Extract any GFM references from the pushed commit messages. If the configured issue-closing regex is matched,
  # close the referenced Issue. Create cross-reference Notes corresponding to any other referenced Mentionables.
  def process_commit_messages ref
    is_default_branch = is_default_branch?(ref)

    @push_commits.each do |commit|
      # Close issues if these commits were pushed to the project's default branch and the commit message matches the
      # closing regex. Exclude any mentioned Issues from cross-referencing even if the commits are being pushed to
      # a different branch.
      issues_to_close = commit.closes_issues(project)
      author = commit_user(commit)

      if !issues_to_close.empty? && is_default_branch
        Thread.current[:current_user] = author
        Thread.current[:current_commit] = commit

        issues_to_close.each { |i| i.close && i.save }
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

  # Produce a hash of post-receive data
  #
  # data = {
  #   before: String,
  #   after: String,
  #   ref: String,
  #   user_id: String,
  #   user_name: String,
  #   project_id: String,
  #   repository: {
  #     name: String,
  #     url: String,
  #     description: String,
  #     homepage: String,
  #   },
  #   commits: Array,
  #   total_commits_count: Fixnum
  # }
  #
  def post_receive_data(oldrev, newrev, ref)
    # Total commits count
    push_commits_count = push_commits.size

    # Get latest 20 commits ASC
    push_commits_limited = push_commits.last(20)

    # Hash to be passed as post_receive_data
    data = {
      before: oldrev,
      after: newrev,
      ref: ref,
      user_id: user.id,
      user_name: user.name,
      project_id: project.id,
      repository: {
        name: project.name,
        url: project.url_to_repo,
        description: project.description,
        homepage: project.web_url,
      },
      commits: [],
      total_commits_count: push_commits_count
    }

    # For performance purposes maximum 20 latest commits
    # will be passed as post receive hook data.
    #
    push_commits_limited.each do |commit|
      data[:commits] << {
        id: commit.id,
        message: commit.safe_message,
        timestamp: commit.committed_date.xmlschema,
        url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/#{commit.id}",
        author: {
          name: commit.author_name,
          email: commit.author_email
        }
      }
    end

    data
  end

  def push_to_existing_branch? ref, oldrev
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    ref_parts[1] =~ /heads/ && oldrev != "0000000000000000000000000000000000000000"
  end

  def push_to_new_branch? ref, oldrev
    ref_parts = ref.split('/')

    ref_parts[1] =~ /heads/ && oldrev == "0000000000000000000000000000000000000000"
  end

  def push_to_branch? ref
    ref =~ /refs\/heads/
  end

  def is_default_branch? ref
    ref == "refs/heads/#{project.default_branch}"
  end

  def commit_user commit
    User.find_for_commit(commit.author_email, commit.author_name) || user
  end
end
