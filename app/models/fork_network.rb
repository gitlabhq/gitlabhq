# frozen_string_literal: true

class ForkNetwork < ApplicationRecord
  belongs_to :root_project, class_name: 'Project'
  belongs_to :organization, class_name: 'Organizations::Organization'

  has_many :fork_network_members
  has_many :projects, through: :fork_network_members

  validate :organization_match

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

  private

  def organization_match
    return unless root_project
    return if root_project.organization_id == organization_id

    errors.add(:organization_id, _("must match the root project organization's ID"))
  end
end
