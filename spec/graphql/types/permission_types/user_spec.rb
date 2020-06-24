# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::User do
  it 'returns user permissions' do
    expected_permissions = [
      :create_snippet
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
