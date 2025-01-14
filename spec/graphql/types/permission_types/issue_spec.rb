# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Issue do
  it do
    expected_permissions = [
      :read_issue, :admin_issue, :update_issue, :reopen_issue,
      :read_design, :create_design, :destroy_design,
      :create_note, :update_design, :move_design,
      :admin_issue_relation
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
