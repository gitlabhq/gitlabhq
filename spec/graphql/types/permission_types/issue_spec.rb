require 'spec_helper'

describe Types::PermissionTypes::Issue do
  it do
    expected_permissions = [
      :read_issue, :admin_issue, :update_issue,
      :create_note, :reopen_issue
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
