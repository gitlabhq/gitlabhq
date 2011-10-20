class UsersProject < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  attr_protected :project_id, :project

  after_commit :update_gitosis_project

  validates_uniqueness_of :user_id, :scope => [:project_id]
  validates_presence_of :user_id
  validates_presence_of :project_id
  validate :user_has_a_role_selected

  delegate :name, :email, :to => :user, :prefix => true

  def update_gitosis_project
    Gitosis.new.configure do |c|
      c.update_project(project.path, project.gitosis_writers)
    end
  end

  def user_has_a_role_selected
    errors.add(:base, "Please choose at least one Role in the Access list") unless read || write || admin
  end

end
# == Schema Information
#
# Table name: users_projects
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  project_id :integer         not null
#  read       :boolean         default(FALSE)
#  write      :boolean         default(FALSE)
#  admin      :boolean         default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#

