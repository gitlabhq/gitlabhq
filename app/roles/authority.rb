# == Authority role
#
# Control access to project repository based on users role in team
#
# Used by Project
#
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
    repository_members[UsersProject::REPORTER]
  end

  def repository_writers
    repository_members[UsersProject::DEVELOPER]
  end

  def repository_masters
    repository_members[UsersProject::MASTER]
  end

  def repository_members
    keys = Hash.new {|h,k| h[k] = [] }
    UsersProject.select("keys.identifier, project_access").
        joins(user: :keys).where(project_id: id).
        each {|row| keys[row.project_access] << [row.identifier] }

    keys[UsersProject::REPORTER] += deploy_keys.pluck(:identifier)
    keys
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
    !users_projects.where(user_id: user.id, project_access: [UsersProject::MASTER]).empty?
  end
end
