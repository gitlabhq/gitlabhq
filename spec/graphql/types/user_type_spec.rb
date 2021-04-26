# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['User'] do
  specify { expect(described_class.graphql_name).to eq('User') }

  specify do
    runtime_type = described_class.resolve_type(build(:user), {})

    expect(runtime_type).to require_graphql_authorizations(:read_user)
  end

  it 'has the expected fields' do
    expected_fields = %w[
      id
      bot
      user_permissions
      snippets
      name
      username
      email
      publicEmail
      avatarUrl
      webUrl
      webPath
      todos
      state
      status
      location
      authoredMergeRequests
      assignedMergeRequests
      reviewRequestedMergeRequests
      groupMemberships
      groupCount
      projectMemberships
      starredProjects
      callouts
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

  describe 'callouts field' do
    subject { described_class.fields['callouts'] }

    it 'returns user callouts' do
      is_expected.to have_graphql_type(Types::UserCalloutType.connection_type)
    end
  end
end
