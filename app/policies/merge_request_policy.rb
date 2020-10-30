# frozen_string_literal: true

class MergeRequestPolicy < IssuablePolicy
  rule { locked }.policy do
    prevent :reopen_merge_request
  end

  # Only users who can read the merge request can comment.
  # Although :read_merge_request is computed in the policy context,
  # it would not be safe to prevent :create_note there, since
  # note permissions are shared, and this would apply too broadly.
  rule { ~can?(:read_merge_request) }.prevent :create_note

  rule { can?(:update_merge_request) }.policy do
    enable :approve_merge_request
  end

  rule { ~anonymous & can?(:read_merge_request) }.policy do
    enable :create_todo
  end
end

MergeRequestPolicy.prepend_if_ee('EE::MergeRequestPolicy')
