# == Schema Information
#
# Table name: namespaces
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  path       :string(255)      not null
#  owner_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)
#

class Group < Namespace
  def add_users_to_project_teams(user_ids, project_access)
    projects.each do |project|
      project.add_users_ids_to_team(user_ids, project_access)
    end
  end

  def users
    users = User.joins(:users_projects).where(users_projects: {project_id: project_ids})
    users = users << owner
    users.uniq
  end

  def human_name
    name
  end
end
