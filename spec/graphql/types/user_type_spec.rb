# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['User'] do
  specify { expect(described_class.graphql_name).to eq('User') }

  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  it 'has the expected fields' do
    expected_fields = %w[
      id
      user_permissions
      snippets
      name
      username
      avatarUrl
      webUrl
      todos
      state
      authoredMergeRequests
      assignedMergeRequests
      groupMemberships
      projectMemberships
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'snippets field' do
    subject { described_class.fields['snippets'] }

    it 'returns snippets' do
      is_expected.to have_graphql_type(Types::SnippetType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::Users::SnippetsResolver)
    end
  end
end
