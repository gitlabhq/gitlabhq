# frozen_string_literal: true

class ProtectedBranch < ApplicationRecord
  include ProtectedRef
  include Gitlab::SQL::Pattern
  include FromUnion
  include EachBatch
  include Presentable

  belongs_to :group, foreign_key: :namespace_id, touch: true, inverse_of: :protected_branches, optional: true

  validate :validate_either_project_or_top_group
  validates :name, uniqueness: { scope: [:project_id, :namespace_id] }, if: :name_changed?

  scope :requiring_code_owner_approval, -> { where(code_owner_approval_required: true) }
  scope :allowing_force_push, -> { where(allow_force_push: true) }
  scope :sorted_by_name, -> { order(name: :asc) }
  scope :sorted_by_namespace_and_name, -> { order(:namespace_id, :name) }

  scope :for_group, ->(group) { where(group: group) }
  scope :preload_access_levels, -> { preload(:push_access_levels, :merge_access_levels) }

  protected_ref_access_levels :merge, :push

  def self.get_ids_by_name(name)
    where(name: name).pluck(:id)
  end

  def self.protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
    if project.empty_repo?
      member_access = project.team.max_member_access(user.id)

      # Admins are always allowed to create the default branch
      return true if user.admin? || user.can?(:admin_project, project)

      # Developers can push if it is allowed by default branch protection settings
      if member_access == Gitlab::Access::DEVELOPER && project.initial_push_to_default_branch_allowed_for_developer?
        return true
      end
    end

    super
  end

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name)
    return true if project.empty_repo? && project.default_branch_protected?
    return false if ref_name.blank?

    ProtectedBranches::CacheService.new(project).fetch(ref_name) do # rubocop: disable CodeReuse/ServiceClass
      self.matching(ref_name, protected_refs: protected_refs(project)).present?
    end
  end

  def self.allow_force_push?(project, ref_name)
    project.all_protected_branches.allowing_force_push.matching(ref_name).any?
  end

  def self.any_protected?(project, ref_names)
    protected_refs(project).any? do |protected_ref|
      ref_names.any? do |ref_name|
        protected_ref.matches?(ref_name)
      end
    end
  end

  def self.protected_refs(project)
    project.all_protected_branches
  end

  # overridden in EE
  def self.branch_requires_code_owner_approval?(project, branch_name)
    false
  end

  def self.by_name(query)
    return none if query.blank?

    where(fuzzy_arel_match(:name, query.downcase))
  end

  def self.downcase_humanized_name
    name.underscore.humanize.downcase
  end

  def default_branch?
    return false unless project.present?

    name == project.default_branch
  end

  def group_level?
    entity.is_a?(Group)
  end

  def project_level?
    entity.is_a?(Project)
  end

  def entity
    group || project
  end

  private

  def validate_either_project_or_top_group
    if !project && !group
      errors.add(:base, _('must be associated with a Group or a Project'))
    elsif project && group
      errors.add(:base, _('cannot be associated with both a Group and a Project'))
    elsif group && group.subgroup?
      errors.add(:base, _('cannot be associated with a subgroup'))
    end
  end
end

ProtectedBranch.prepend_mod_with('ProtectedBranch')
