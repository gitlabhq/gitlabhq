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

  def type
    :role
  end

  def role?
    type == :role
  end

  def humanize
    # humanize_role
    # humanize_member_role
    # humanize_user
    # humanize_group
    # humanize_deploy_key
    send(:"humanize_#{type}") # rubocop:disable GitlabSecurity/PublicSend -- Intentional meta programming to direct to correct type
  end

  # Normally this check runs when pushing to a project so current_project is
  # passed in, however, if we are checking if a user can has access to delete
  # aka unprotect a protected branch then current project will be nil.
  def check_access(current_user, current_project = nil)
    return false if current_user.nil? || no_access?
    return current_user.admin? if admin_access?

    # role_access_allowed?
    # member_role_access_allowed?
    # user_access_allowed?
    # group_access_allowed?
    # deploy_key_access_allowed?
    send(:"#{type}_access_allowed?", current_user, current_project) # rubocop:disable GitlabSecurity/PublicSend -- Intentional meta programming to direct check to correct type
  end

  private

  def humanize_role
    self.class.humanize(access_level)
  end

  def admin_access?
    role? && access_level == ::Gitlab::Access::ADMIN
  end

  def no_access?
    role? && access_level == Gitlab::Access::NO_ACCESS
  end

  # current_project is only present when merging or pushing into a protected
  # branch/tag, otherwise we are checking a project or group level protected
  # branch can be unprotected by current_user.
  #
  # Project level protected branches have a protected_ref_project and group
  # level protected branches have a protected_branch_group.
  #
  # Protected tags cannot be configured at group level hence the naming
  # difference.
  def role_access_allowed?(current_user, current_project)
    if current_project
      role_access_allowed_for_project?(current_user, current_project)
    elsif protected_ref_project
      role_access_allowed_for_project?(current_user, protected_ref_project)
    elsif protected_branch_group
      protected_branch_group.max_member_access_for_user(current_user) >= access_level
    end
  end

  def role_access_allowed_for_project?(current_user, project)
    # current_user could be a group member with inherited membership in project
    # or could have direct membership to project with a higher role so we check
    # max_member_access
    current_user.can?(:push_code, project) &&
      project.team.max_member_access(current_user.id) >= access_level
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
