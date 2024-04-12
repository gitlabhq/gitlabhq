# frozen_string_literal: true

module Members
  class MemberApproval < ApplicationRecord
    include Presentable

    enum status: { pending: 0, approved: 1, denied: 2 }

    belongs_to :user
    belongs_to :member, optional: true
    belongs_to :member_namespace, class_name: 'Namespace'
    belongs_to :requested_by, inverse_of: :requested_member_approvals, class_name: 'User',
      optional: true
    belongs_to :reviewed_by, inverse_of: :reviewed_member_approvals, class_name: 'User',
      optional: true

    validates :new_access_level, presence: true
    validates :user, presence: true
    validates :member_namespace, presence: true
    validate :validate_unique_pending_approval, on: [:create, :update]

    scope :pending_member_approvals, ->(member_namespace_id) do
      where(member_namespace_id: member_namespace_id).where(status: statuses[:pending])
    end

    private

    def validate_unique_pending_approval
      return unless pending?

      scope = self.class.where(user_id: user_id, member_namespace_id: member_namespace_id,
        new_access_level: new_access_level, status: self.class.statuses[:pending])
      scope = scope.where.not(id: id) if persisted?
      return unless scope.exists?

      errors.add(:base, 'A pending approval for the same user, namespace, and access level already exists.')
    end
  end
end
