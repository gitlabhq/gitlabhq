# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#  description :string(255)      default(""), not null
#

class Group < Namespace
  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups

  def add_users(user_ids, group_access)
    user_ids.compact.each do |user_id|
      self.users_groups.create(user_id: user_id, group_access: group_access)
    end
  end

  def add_users_to_project_teams(user_ids, project_access)
    UsersProject.add_users_into_projects(
      projects.map(&:id),
      user_ids,
      project_access
    )
  end

  def users
    users = User.joins(:users_projects).where(users_projects: {project_id: project_ids})
    users = users << owner
    users.uniq
  end

  def human_name
    name
  end

  def truncate_teams
    UsersProject.truncate_teams(project_ids)
  end

  def owners
    @owners ||= (users_groups.owners.map(&:user) << owner)
  end
end
