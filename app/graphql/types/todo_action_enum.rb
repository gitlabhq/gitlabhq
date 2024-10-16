# frozen_string_literal: true

module Types
  class TodoActionEnum < BaseEnum
    value 'assigned', value: 1, description: 'User was assigned.'
    value 'mentioned', value: 2, description: 'User was mentioned.'
    value 'build_failed', value: 3, description: 'Build triggered by the user failed.'
    value 'marked', value: 4, description: 'User added a to-do item.'
    value 'approval_required', value: 5, description: 'User was set as an approver.'
    value 'unmergeable', value: 6, description: 'Merge request authored by the user could not be merged.'
    value 'directly_addressed', value: 7, description: 'User was directly addressed.'
    value 'merge_train_removed', value: 8, description: 'Merge request authored by the user was removed from the merge train.'
    value 'review_requested', value: 9, description: 'Review was requested from the user.'
    value 'member_access_requested', value: 10, description: 'Group or project access requested from the user.'
    value 'review_submitted', value: 11, description: 'Merge request authored by the user received a review.'
    value 'okr_checkin_requested', value: 12, description: 'An OKR assigned to the user requires an update.'
    value 'added_approver', value: 13, description: 'User was added as an approver.'
    value 'ssh_key_expired', value: 14, description: 'SSH key of the user has expired.'
    value 'ssh_key_expiring_soon', value: 15, description: 'SSH key of the user will expire soon.'
  end
end
