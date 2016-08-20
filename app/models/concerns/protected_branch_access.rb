module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    validates :user_id, uniqueness: { scope: :protected_branch, allow_nil: true }
    validates :access_level, uniqueness: { scope: :protected_branch, unless: :user_id?, conditions: -> { where(user_id: nil) } }
  end

  def type
    if self.user.present?
      :user
    else
      :role
    end
  end

  def humanize
    return self.user.name if self.user.present?

    self.class.human_access_levels[self.access_level]
  end
end
