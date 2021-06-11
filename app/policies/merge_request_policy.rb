# frozen_string_literal: true

class MergeRequestPolicy < IssuablePolicy
  rule { locked }.policy do
    prevent :reopen_merge_request
  end

  # Only users who can read the merge request can comment.
  # Although :read_merge_request is computed in the policy context,
  # it would not be safe to prevent :create_note there, since
  # note permissions are shared, and this would apply too broadly.
  rule { ~can?(:read_merge_request) }.policy do
    prevent :create_note
    prevent :accept_merge_request
  end

  rule { can?(:update_merge_request) }.policy do
    enable :approve_merge_request
  end

  rule { ~anonymous & can?(:read_merge_request) }.policy do
    enable :create_todo
    enable :update_subscription
  end

  condition(:can_merge) { @subject.can_be_merged_by?(@user) }

  rule { can_merge }.policy do
    enable :accept_merge_request
  end

  rule { can?(:admin_merge_request) }.policy do
    enable :set_merge_request_metadata
  end
end

MergeRequestPolicy.prepend_mod_with('MergeRequestPolicy')
