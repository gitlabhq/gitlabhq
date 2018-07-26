# EE-specific code related to protected branch/tag access levels.
#
# Note: Don't directly include this concern into a model class.
# Instead, include `ProtectedBranchAccess` or `ProtectedTagAccess`, which in
# turn include this concern. A number of methods here depend on
# `ProtectedRefAccess` being next up in the ancestor chain.

module EE
  module ProtectedRefAccess
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    included do
      belongs_to :user
      belongs_to :group

      protected_type = self.parent.model_name.singular
      validates :group_id, uniqueness: { scope: protected_type, allow_nil: true }
      validates :user_id, uniqueness: { scope: protected_type, allow_nil: true }
      validates :access_level, uniqueness: { scope: protected_type, if: :role?,
                                             conditions: -> { where(user_id: nil, group_id: nil) } }
      validates :group, :user,
               absence: true,
               unless: :protected_refs_for_users_required_and_available
    end

    def type
      if self.user.present?
        :user
      elsif self.group.present?
        :group
      else
        :role
      end
    end

    # Is this a role-based access level?
    override :role?
    def role?
      type == :role
    end

    override :humanize
    def humanize
      return self.user.name if self.user.present?
      return self.group.name if self.group.present?

      super
    end

    override :check_access
    def check_access(user)
      return true if user.admin?
      return user.id == self.user_id if self.user.present?
      return group.users.exists?(user.id) if self.group.present?

      super
    end

    # We don't need to validate the license if this access applies to a role.
    #
    # If it applies to a user/group we can only skip validation `nil`-validation
    # if the feature is available
    def protected_refs_for_users_required_and_available
      type != :role && project.feature_available?(:protected_refs_for_users)
    end
  end
end
