module Authority
  # Compatible with all access rights
  # Should be rewrited for new access rights
  def add_access(user, *access)
    access = if access.include?(:admin) 
               { project_access: UsersProject::MASTER } 
             elsif access.include?(:write)
               { project_access: UsersProject::DEVELOPER } 
             else
               { project_access: UsersProject::REPORTER } 
             end
    opts = { user: user }
    opts.merge!(access)
    users_projects.create(opts)
  end

  def reset_access(user)
    users_projects.where(project_id: self.id, user_id: user.id).destroy if self.id
  end

  def repository_readers
    keys = Key.joins({user: :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::REPORTER)
    keys.map(&:identifier) + deploy_keys.map(&:identifier) + (public? ? ['@all'] : [])
  end

  def repository_writers
    keys = Key.joins({user: :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::DEVELOPER)
    keys.map(&:identifier)
  end

  def repository_masters
    keys = Key.joins({user: :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::MASTER)
    keys.map(&:identifier)
  end

  def allow_read_for?(user)
    !users_projects.where(user_id: user.id).empty?
  end

  def guest_access_for?(user)
    !users_projects.where(user_id: user.id).empty?
  end

  def report_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::REPORTER, UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def dev_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def master_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::MASTER]).empty? || owner_id == user.id
  end
end
