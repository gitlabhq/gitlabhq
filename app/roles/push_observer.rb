# Includes methods for handling Git Push events
#
# Triggered by PostReceive job
module PushObserver
  # This method will be called after each post receive and only if the provided
  # user is present in GitLab.
  #
  # All callbacks for post receive should be placed here.
  def trigger_post_receive(oldrev, newrev, ref, user)
    data = post_receive_data(oldrev, newrev, ref, user)

    # Create push event
    self.observe_push(data)

    if push_to_branch? ref, oldrev
      # Close merged MR
      self.update_merge_requests(oldrev, newrev, ref, user)

      # Execute web hooks
      self.execute_hooks(data.dup)

      # Execute project services
      self.execute_services(data.dup)
    end

    # Create satellite
    self.satellite.create unless self.satellite.exists?

    # Discover the default branch, but only if it hasn't already been set to
    # something else
    if default_branch.nil?
      update_attributes(default_branch: discover_default_branch)
    end
  end

  def push_to_branch? ref, oldrev
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    !(ref_parts[1] !~ /heads/ || oldrev == "00000000000000000000000000000000")
  end

  def observe_push(data)
    Event.create(
      project: self,
      action: Event::Pushed,
      data: data,
      author_id: data[:user_id]
    )
  end

  def execute_hooks(data)
    hooks.each { |hook| hook.execute(data) }
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      service.execute(data) if service.active
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
  def post_receive_data(oldrev, newrev, ref, user)

    push_commits = commits_between(oldrev, newrev)

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
      repository: {
        name: name,
        url: url_to_repo,
        description: description,
        homepage: web_url,
      },
      commits: [],
      total_commits_count: push_commits_count
    }

    # For perfomance purposes maximum 20 latest commits
    # will be passed as post receive hook data.
    #
    push_commits_limited.each do |commit|
      data[:commits] << {
        id: commit.id,
        message: commit.safe_message,
        timestamp: commit.date.xmlschema,
        url: "#{Gitlab.config.gitlab.url}/#{path_with_namespace}/commit/#{commit.id}",
        author: {
          name: commit.author_name,
          email: commit.author_email
        }
      }
    end

    data
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.commits_between(oldrev, newrev).map(&:id)

    # Update code for merge requests
    mrs = self.merge_requests.opened.find_all_by_branch(branch_name).all
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).all
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| merge_request.merge!(user.id) }

    true
  end
end
