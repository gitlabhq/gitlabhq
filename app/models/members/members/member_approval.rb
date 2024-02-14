# frozen_string_literal: true

module Members
  class MemberApproval < ApplicationRecord
    enum status: { pending: 0, approved: 1, denied: 2 }

    belongs_to :member
    belongs_to :member_namespace, class_name: 'Namespace'
    belongs_to :requested_by, inverse_of: :requested_member_approvals, class_name: 'User',
      optional: true
    belongs_to :reviewed_by, inverse_of: :reviewed_member_approvals, class_name: 'User',
      optional: true

    validates :new_access_level, presence: true
    validates :old_access_level, presence: true
    validate :validate_unique_pending_approval, on: [:create, :update]

    private

    def validate_unique_pending_approval
      if pending? && self.class.where(member_id: member_id, member_namespace_id: member_namespace_id,
        new_access_level: new_access_level, status: 0).exists?
        errors.add(:base, 'A pending approval for the same member, namespace, and access level already exists.')
      end
    end
  end
end
