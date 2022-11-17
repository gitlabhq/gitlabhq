# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Ci::Runner do
  it do
    expected_permissions = [
      :read_runner, :update_runner, :delete_runner, :assign_runner
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
