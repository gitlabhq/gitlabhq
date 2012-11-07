module PushEvent
  def valid_push?
    data[:ref]
  rescue => ex
    false
  end

  def tag?
    data[:ref]["refs/tags"]
  end

  def branch?
    data[:ref]["refs/heads"]
  end

  def new_branch?
    commit_from =~ /^00000/
  end

  def new_ref?
    commit_from =~ /^00000/
  end

  def rm_ref?
    commit_to =~ /^00000/
  end

  def md_ref?
    !(rm_ref? || new_ref?)
  end

  def commit_from
    data[:before]
  end

  def commit_to
    data[:after]
  end

  def ref_name
    if tag?
      tag_name
    else
      branch_name
    end
  end

  def branch_name
    @branch_name ||= data[:ref].gsub("refs/heads/", "")
  end

  def tag_name
    @tag_name ||= data[:ref].gsub("refs/tags/", "")
  end

  # Max 20 commits from push DESC
  def commits
    @commits ||= data[:commits].map { |commit| project.commit(commit[:id]) }.reverse
  end

  def commits_count 
    data[:total_commits_count] || commits.count || 0
  end

  def ref_type
    tag? ? "tag" : "branch"
  end

  def push_action_name
    if new_ref?
      "pushed new"
    elsif rm_ref?
      "deleted"
    else
      "pushed to"
    end
  end

  def parent_commit
    project.commit(commit_from)
  rescue => ex
    nil
  end

  def last_commit
    project.commit(commit_to)
  rescue => ex
    nil
  end

  def push_with_commits? 
    md_ref? && commits.any? && parent_commit && last_commit
  rescue Grit::NoSuchPathError
    false
  end

  def last_push_to_non_root?
    branch? && project.default_branch != branch_name
  end
end
