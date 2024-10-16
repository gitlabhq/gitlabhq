# frozen_string_literal: true

module ProtectedRefAccess
  include Importable
  extend ActiveSupport::Concern

  class_methods do
    def human_access_levels
      {
        Gitlab::Access::DEVELOPER => 'Developers + Maintainers',
        Gitlab::Access::MAINTAINER => 'Maintainers',
        Gitlab::Access::ADMIN => 'Instance admins',
        Gitlab::Access::NO_ACCESS => 'No one'
      }.slice(*allowed_access_levels)
    end

    def allowed_access_levels
      levels = [
        Gitlab::Access::DEVELOPER,
        Gitlab::Access::MAINTAINER,
        Gitlab::Access::ADMIN,
        Gitlab::Access::NO_ACCESS
      ]

      return levels unless Gitlab.com?

      levels.excluding(Gitlab::Access::ADMIN)
    end

    def humanize(access_level)
      human_access_levels[access_level]
    end

    def non_role_types
      []
    end
  end

  included do
    scope :maintainer, -> { where(access_level: Gitlab::Access::MAINTAINER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }
    # If there aren't any `non_role_types`, `all` will be returned. If any
    # `non_role_types` are present we add them to the query i.e.
    # => all.where("#{'user'}_id": nil).where("#{'group'}_id": nil)
    scope :for_role, -> { non_role_types.inject(all) { |scope, type| scope.where("#{type}_id": nil) } }

    protected_ref_fk = "#{module_parent.model_name.singular}_id"
    validates :access_level,
      presence: true,
      inclusion: { in: allowed_access_levels },
      uniqueness: { scope: protected_ref_fk, conditions: -> { for_role } },
      if: :role?
  end

  def humanize
    self.class.humanize(access_level)
  end

  def type
    :role
  end

  def role?
    type == :role
  end

  def check_access(current_user, current_project = project)
    return false if current_user.nil? || no_access?
    return current_user.admin? if admin_access?

    yield if block_given?

    user_can_access?(current_user, current_project)
  end

  private

  def admin_access?
    role? && access_level == ::Gitlab::Access::ADMIN
  end

  def no_access?
    role? && access_level == Gitlab::Access::NO_ACCESS
  end

  def user_can_access?(current_user, current_project)
    # NOTE: A user could be a group member which would be inherited in
    # projects, however, the same user can have direct membership to a project
    # with a higher role. For this reason we need to check group-level rules
    # against the current project when merging an MR or pushing changes to a
    # protected branch.
    if current_project
      current_user.can?(:push_code, current_project) &&
        current_project.team.max_member_access(current_user.id) >= access_level
    elsif protected_branch_group
      protected_branch_group.max_member_access_for_user(current_user) >= access_level
    end
  end
end

ProtectedRefAccess.include_mod_with('ProtectedRefAccess::Scopes')
ProtectedRefAccess.prepend_mod_with('ProtectedRefAccess')

# When using `prepend` (or `include` for that matter), the `ClassMethods`
# constants are not merged. This means that `class_methods` in
# `EE::ProtectedRefAccess` would be ignored.
#
# To work around this, we prepend the `ClassMethods` constant manually.
ProtectedRefAccess::ClassMethods.prepend_mod_with('ProtectedRefAccess::ClassMethods')
