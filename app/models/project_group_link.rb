# frozen_string_literal: true

class ProjectGroupLink < ApplicationRecord
  include Expirable
  include EachBatch

  belongs_to :project
  belongs_to :group

  validates :project_id, presence: true
  validates :group, presence: true
  validates :group_id, uniqueness: { scope: [:project_id], message: _("already shared with this group") }
  validates :group_access, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.values }, presence: true
  validate :different_group

  scope :non_guests, -> { where('group_access > ?', Gitlab::Access::GUEST) }

  alias_method :shared_with_group, :group

  def self.access_options
    Gitlab::Access.options
  end

  def self.default_access
    Gitlab::Access::DEVELOPER
  end

  def self.search(query)
    joins(:group).merge(Group.search(query))
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
      errors.add(:base, _("Project cannot be shared with the group it is in or one of its ancestors."))
    end
  end
end

ProjectGroupLink.prepend_mod_with('ProjectGroupLink')
