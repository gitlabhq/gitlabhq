# frozen_string_literal: true

module API
  module Entities
    class MergeRequestApprovals < Grape::Entity
      expose :user_has_approved, documentation: { type: 'boolean' } do |merge_request, options|
        merge_request.approved_by?(options[:current_user])
      end

      expose :user_can_approve, documentation: { type: 'boolean' } do |merge_request, options|
        merge_request.eligible_for_approval_by?(options[:current_user])
      end

      expose :approved, documentation: { type: 'boolean' } do |merge_request|
        merge_request.approvals.present?
      end

      expose :approved_by, using: ::API::Entities::Approvals do |merge_request|
        merge_request.approvals
      end
    end
  end
end
