# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Group, feature_category: :groups_and_projects do
  it 'has the correct permissions' do
    expected_permissions = [
      :read_group, :create_projects, :create_custom_emoji, :remove_group, :view_edit_page
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
