module GitPush
  def observe_push(oldrev, newrev, ref, user)
    data = post_receive_data(oldrev, newrev, ref, user)

    Event.create(
      :project => self,
      :action => Event::Pushed,
      :data => data,
      :author_id => data[:user_id]
    )
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.commits_between(oldrev, newrev).map(&:id)

    # Update code for merge requests
    mrs = self.merge_requests.opened.find_all_by_branch(branch_name).all
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

    # Close merge requests
    mrs = self.merge_requests.opened.where(:target_branch => branch_name).all
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| merge_request.merge!(user.id) }

    true
  end

  def execute_web_hooks(oldrev, newrev, ref, user)
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    return if ref_parts[1] !~ /heads/ || oldrev == "00000000000000000000000000000000"

    data = post_receive_data(oldrev, newrev, ref, user)

    web_hooks.each { |web_hook| web_hook.execute(data) }
  end

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
        url: web_url,
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
        url: "#{Gitlab.config.url}/#{code}/commits/#{commit.id}",
        author: {
          name: commit.author_name,
          email: commit.author_email
        }
      }
    end

    data
  end


  # This method will be called after each post receive
  # and only if user present in gitlab.
  # All callbacks for post receive should be placed here
  #
  def trigger_post_receive(oldrev, newrev, ref, user)
    # Create push event
    self.observe_push(oldrev, newrev, ref, user)

    # Close merged MR
    self.update_merge_requests(oldrev, newrev, ref, user)

    # Execute web hooks
    self.execute_web_hooks(oldrev, newrev, ref, user)

    # Create satellite
    self.satellite.create unless self.satellite.exists?
  end
end
