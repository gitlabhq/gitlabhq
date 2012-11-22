# == Schema Information
#
# Table name: groups
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  code       :string(255)      not null
#  owner_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Group < Namespace
  def users
    User.joins(:users_projects).where(users_projects: {project_id: project_ids}).uniq
  end
end
