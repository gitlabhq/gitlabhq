class UsersProject < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  attr_protected :project_id, :project

  after_save :update_repository
  after_destroy :update_repository

  validates_uniqueness_of :user_id, :scope => [:project_id]
  validates_presence_of :user_id
  validates_presence_of :project_id

  delegate :name, :email, :to => :user, :prefix => true

  def update_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_project(project.path, project)
    end
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

