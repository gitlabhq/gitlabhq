# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::MergeRequest do
  it do
    expected_permissions = [
      :read_merge_request, :admin_merge_request, :update_merge_request,
      :create_note, :push_to_source_branch, :remove_source_branch,
      :cherry_pick_on_current_merge_request, :revert_on_current_merge_request,
      :can_merge, :can_approve
    ]

    expect(described_class).to have_graphql_fields(expected_permissions)
  end
end
