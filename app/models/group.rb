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
  def users
    User.joins(:users_projects).where(users_projects: {project_id: project_ids}).uniq
  end

  def human_name
    name
  end
end
