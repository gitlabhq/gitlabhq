# EE-specific code related to protected branch access levels.
#
# Note: Don't directly include this concern into a model class.
# Instead, include `ProtectedBranchAccess`, which in turn includes
# this concern. A number of methods here depend on `ProtectedBranchAccess`
# being next up in the ancestor chain.

module EE
  module ProtectedBranchAccess
    extend ActiveSupport::Concern

    included do
      belongs_to :user
      belongs_to :group

      validates :group_id, uniqueness: { scope: :protected_branch, allow_nil: true }
      validates :user_id, uniqueness: { scope: :protected_branch, allow_nil: true }
      validates :access_level, uniqueness: { scope: :protected_branch, if: :role?,
                                             conditions: -> { where(user_id: nil, group_id: nil) } }

      scope :by_user, -> (user) { where(user: user ) }
      scope :by_group, -> (group) { where(group: group ) }
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
    def role?
      type == :role
    end

    def humanize
      return self.user.name if self.user.present?
      return self.group.name if self.group.present?

      super
    end

    def check_access(user)
      return true if user.is_admin?
      return user.id == self.user_id if self.user.present?
      return group.users.exists?(user.id) if self.group.present?

      super
    end
  end
end
