# frozen_string_literal: true

module Types
  module PermissionTypes
    class MergeRequest < BasePermissionType
      present_using MergeRequestPresenter
      description 'Check permissions for the current user on a merge request'
      graphql_name 'MergeRequestPermissions'

      abilities :read_merge_request, :admin_merge_request,
                :update_merge_request, :create_note

      permission_field :push_to_source_branch, method: :can_push_to_source_branch?, calls_gitaly: true
      permission_field :remove_source_branch, method: :can_remove_source_branch?, calls_gitaly: true
      permission_field :cherry_pick_on_current_merge_request, method: :can_cherry_pick_on_current_merge_request?
      permission_field :revert_on_current_merge_request, method: :can_revert_on_current_merge_request?
    end
  end
end
