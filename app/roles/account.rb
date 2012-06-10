module Account 
  def identifier
    email.gsub /[@.]/, "_"
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

  def last_activity_project
    projects.first
  end

  def first_name
    name.split.first unless name.blank?
  end

  def cared_merge_requests
    MergeRequest.where("author_id = :id or assignee_id = :id", :id => self.id).opened
  end

  def project_ids
    projects.map(&:id)
  end

  # Remove user from all projects and
  # set blocked attribute to true
  def block
    users_projects.all.each do |membership|
      return false unless membership.destroy
    end

    self.blocked = true
    save
  end

  def projects_limit_percent
    return 100 if projects_limit.zero?
    (my_own_projects.count.to_f / projects_limit) * 100
  end
end
