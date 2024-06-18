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
    validates :metadata, json_schema: { filename: "members_approval_request_metadata" }
  end
end

Members::MemberApproval.prepend_mod
