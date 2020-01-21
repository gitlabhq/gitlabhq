# frozen_string_literal: true

class ProjectGroupLink < ApplicationRecord
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
  validates :group_id, uniqueness: { scope: [:project_id], message: _("already shared with this group") }
  validates :group_access, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.values }, presence: true
  validate :different_group

  after_commit :refresh_group_members_authorized_projects

  alias_method :shared_with_group, :group

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
      errors.add(:base, _("Project cannot be shared with the group it is in or one of its ancestors."))
    end
  end

  def refresh_group_members_authorized_projects
    group.refresh_members_authorized_projects
  end
end

ProjectGroupLink.prepend_if_ee('EE::ProjectGroupLink')
