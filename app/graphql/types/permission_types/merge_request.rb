# frozen_string_literal: true

module Types
  module PermissionTypes
    class MergeRequest < BasePermissionType
      graphql_name 'MergeRequestPermissions'
      description 'Check permissions for the current user on a merge request'

      present_using MergeRequestPresenter

      PERMISSION_FIELDS = %i[push_to_source_branch
        remove_source_branch
        cherry_pick_on_current_merge_request
        revert_on_current_merge_request].freeze

      abilities :read_merge_request, :admin_merge_request,
        :update_merge_request, :create_note

      PERMISSION_FIELDS.each do |field_name|
        permission_field field_name, method: :"can_#{field_name}?", calls_gitaly: true
      end

      permission_field :can_merge, calls_gitaly: true
      permission_field :can_approve, calls_gitaly: true

      def can_merge
        object.can_be_merged_by?(context[:current_user])
      end

      def can_approve
        object.eligible_for_approval_by?(context[:current_user])
      end
    end
  end
end
