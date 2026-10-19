# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::FrecentGroupsResolver, feature_category: :navigation do
  include GraphqlHelpers

  it_behaves_like 'namespace visits resolver'

  describe '#resolve with no current organization' do
    let_it_be(:current_user) { create(:user) }

    def resolve_items(scope_to_organization:)
      sync(
        resolve(
          described_class,
          args: { scope_to_organization: scope_to_organization },
          ctx: { current_user: current_user, current_organization: nil }
        )
      )
    end

    context 'when scoping to the organization was requested' do
      it 'errors rather than returning groups from every organization' do
        expect(resolve_items(scope_to_organization: true))
          .to be_a(Gitlab::Graphql::Errors::ArgumentError)
          .and have_attributes(message: described_class::ORGANIZATION_UNAVAILABLE_ERROR)
      end
    end

    context 'when scoping to the organization was not requested' do
      it 'returns groups from every organization' do
        expect(resolve_items(scope_to_organization: false)).to be_an_instance_of(Array)
      end
    end
  end
end
