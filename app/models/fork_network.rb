class ForkNetwork < ActiveRecord::Base
  belongs_to :root_project, class_name: 'Project'
  has_many :fork_network_members
  has_many :projects, through: :fork_network_members

  after_create :add_root_as_member, if: :root_project

  def add_root_as_member
    projects << root_project
  end

  def find_forks_in(other_projects)
    projects.where(id: other_projects)
  end

  def merge_requests
    MergeRequest.where(target_project: projects)
  end
end
