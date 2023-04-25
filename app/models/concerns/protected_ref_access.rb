# frozen_string_literal: true

module ProtectedRefAccess
  extend ActiveSupport::Concern

  class_methods do
    def human_access_levels
      {
        Gitlab::Access::DEVELOPER => "Developers + Maintainers",
        Gitlab::Access::MAINTAINER => "Maintainers",
        Gitlab::Access::NO_ACCESS => "No one"
      }
    end

    def allowed_access_levels
      [
        Gitlab::Access::MAINTAINER,
        Gitlab::Access::DEVELOPER,
        Gitlab::Access::NO_ACCESS
      ]
    end

    def humanize(access_level)
      human_access_levels[access_level]
    end
  end

  included do
    scope :maintainer, -> { where(access_level: Gitlab::Access::MAINTAINER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }
    scope :by_user, -> (user) { where(user_id: user) }
    scope :by_group, -> (group) { where(group_id: group) }
    scope :for_role, -> { where(user_id: nil, group_id: nil) }
    scope :for_user, -> { where.not(user_id: nil) }
    scope :for_group, -> { where.not(group_id: nil) }

    validates :access_level, presence: true, if: :role?, inclusion: { in: allowed_access_levels }
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

  def check_access(user)
    return false unless user
    return true if user.admin?

    user.can?(:push_code, project) &&
      project.team.max_member_access(user.id) >= access_level
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
