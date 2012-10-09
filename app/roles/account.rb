module Account
  # Returns a string for use as a Gitolite user identifier
  #
  # Note that Gitolite 2.x requires the following pattern for users:
  #
  #   ^@?[0-9a-zA-Z][0-9a-zA-Z._\@+-]*$
  def identifier
    # Replace non-word chars with underscores, then make sure it starts with
    # valid chars
    email.gsub(/\W/, '_').gsub(/\A([\W\_])+/, '')
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def can_create_project?
    projects_limit > my_own_projects.count
  end

  def can_create_group?
    is_admin?
  end

  def last_activity_project
    projects.first
  end

  def first_name
    name.split.first unless name.blank?
  end

  def cared_merge_requests
    MergeRequest.where("author_id = :id or assignee_id = :id", id: self.id).opened
  end

  def project_ids
    projects.map(&:id)
  end

  # Remove user from all projects and
  # set blocked attribute to true
  def block
    users_projects.find_each do |membership|
      return false unless membership.destroy
    end

    self.blocked = true
    save
  end

  def projects_limit_percent
    return 100 if projects_limit.zero?
    (my_own_projects.count.to_f / projects_limit) * 100
  end

  def recent_push project_id = nil
    # Get push events not earlier than 2 hours ago
    events = recent_events.code_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(project_id: project_id) if project_id

    # Take only latest one
    events = events.recent.limit(1).first
  end

  def projects_with_events
    projects.includes(:events).order("events.created_at DESC")
  end
end
