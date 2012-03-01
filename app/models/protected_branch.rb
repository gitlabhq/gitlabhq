class ProtectedBranch < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :project_id
  validates_presence_of :name

  after_save :update_repository
  after_destroy :update_repository

  def update_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_project(project.path, project)
    end
  end

  def commit
    project.commit(self.name)
  end
end
# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer         not null, primary key
#  project_id :integer         not null
#  name       :string(255)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

