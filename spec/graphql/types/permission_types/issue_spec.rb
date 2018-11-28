require 'spec_helper'

describe Types::PermissionTypes::Issue do
  it do
    expected_permissions = [
      :read_issue, :admin_issue, :update_issue,
      :create_note, :reopen_issue
    ]

    expect(described_class).to have_graphql_fields(expected_permissions)
  end
end
