# frozen_string_literal: true

module Types
  module PermissionTypes
    class MergeRequest < BasePermissionType
      PERMISSION_FIELDS = %i[push_to_source_branch
                             remove_source_branch
                             cherry_pick_on_current_merge_request
                             revert_on_current_merge_request].freeze

      present_using MergeRequestPresenter
      description 'Check permissions for the current user on a merge request'
      graphql_name 'MergeRequestPermissions'

      abilities :read_merge_request, :admin_merge_request,
                :update_merge_request, :create_note

      PERMISSION_FIELDS.each do |field_name|
        permission_field field_name, method: :"can_#{field_name}?", calls_gitaly: true
      end
    end
  end
end
