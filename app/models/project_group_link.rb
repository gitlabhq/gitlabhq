# frozen_string_literal: true

class ProjectGroupLink < ApplicationRecord
  include Expirable
  include EachBatch
  include AfterCommitQueue

  belongs_to :project
  belongs_to :group

  validates :project_id, presence: true
  validates :group, presence: true
  validates :group_id, uniqueness: { scope: [:project_id], message: N_("already shared with this group") }
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validate :different_group

  scope :non_guests, -> { where('project_group_links.group_access > ?', Gitlab::Access::GUEST) }
  scope :in_group, ->(group_ids) { where(group_id: group_ids) }
  scope :for_projects, ->(project_ids) { where(project_id: project_ids) }

  alias_method :shared_with_group, :group
  alias_method :shared_from, :project

  def self.search(query)
    joins(:group).merge(Group.search(query))
  end

  def human_access
    Gitlab::Access.human_access(self.group_access)
  end

  def owner_access?
    group_access.to_i == Gitlab::Access::OWNER
  end

  private

  def different_group
    return unless self.group && self.project

    project_group = self.project.group
    return unless project_group

    group_ids = project_group.ancestors.map(&:id).push(project_group.id)

    if group_ids.include?(self.group.id)
      errors.add(:base, _("Project cannot be shared with the group it is in or one of its ancestors."))
    end
  end
end

ProjectGroupLink.prepend_mod_with('ProjectGroupLink')
