class ProtectedBranch < ActiveRecord::Base
  include GitHost

  belongs_to :project
  validates_presence_of :project_id
  validates_presence_of :name

  after_save :update_repository
  after_destroy :update_repository

  def update_repository
    git_host.update_repository(project)
  end

  def commit
    project.commit(self.name)
  end
end
# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer(4)      not null, primary key
#  project_id :integer(4)      not null
#  name       :string(255)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

