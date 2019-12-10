# frozen_string_literal: true

require 'spec_helper'

describe Types::PermissionTypes::Snippet do
  it 'returns the snippets permissions' do
    expected_permissions = [
      :create_note, :award_emoji, :read_snippet, :update_snippet, :admin_snippet
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
