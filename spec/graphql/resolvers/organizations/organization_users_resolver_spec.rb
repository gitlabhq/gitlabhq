# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Organizations::OrganizationUsersResolver, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_owner) { create(:organization_owner, organization: organization) }
  let_it_be(:searched_user) { create(:user, organizations: [], username: 'searchable-member') }
  let_it_be(:organization_user) { create(:organization_user, organization: organization, user: searched_user) }

  let(:current_user) { organization_owner.user }
  let(:args) { {} }

  subject(:result) { resolve(described_class, obj: organization, args: args, ctx: { current_user: current_user }) }

  it 'defines an optional search argument' do
    argument = described_class.arguments['search']

    expect(argument.type).to eq(GraphQL::Types::String)
    expect(argument.type).not_to be_non_null
  end

  it 'returns all organization users' do
    expect(result.items).to contain_exactly(organization_owner, organization_user)
  end

  context 'with search argument' do
    let(:args) { { search: 'searchable' } }

    it 'returns the matching organization users' do
      expect(result.items).to contain_exactly(organization_user)
    end

    context 'without an HTTP request' do
      it 'still applies the rate limit' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:autocomplete_users, scope: { user: current_user }).and_return(true)

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) { result }
      end
    end
  end
end
