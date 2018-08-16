# frozen_string_literal: true

class ProjectGroupLink < ActiveRecord::Base
  include Expirable

  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MAINTAINER = 40
  MASTER = MAINTAINER # @deprecated

  belongs_to :project
  belongs_to :group

  validates :project_id, presence: true
  validates :group, presence: true
  validates :group_id, uniqueness: { scope: [:project_id], message: "already shared with this group" }
  validates :group_access, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.values }, presence: true
  validate :different_group

  before_destroy :delete_branch_protection
  after_commit :refresh_group_members_authorized_projects

  def self.access_options
    Gitlab::Access.options
  end

  def self.default_access
    DEVELOPER
  end

  def human_access
    self.class.access_options.key(self.group_access)
  end

  private

  def different_group
    return unless self.group && self.project

    project_group = self.project.group
    return unless project_group

    group_ids = project_group.ancestors.map(&:id).push(project_group.id)

    if group_ids.include?(self.group.id)
      errors.add(:base, "Project cannot be shared with the group it is in or one of its ancestors.")
    end
  end

  def delete_branch_protection
    if group.present? && project.present?
      project.protected_branches.merge_access_by_group(group).destroy_all # rubocop: disable DestroyAll
      project.protected_branches.push_access_by_group(group).destroy_all # rubocop: disable DestroyAll
    end
  end

  def refresh_group_members_authorized_projects
    group.refresh_members_authorized_projects
  end
end
