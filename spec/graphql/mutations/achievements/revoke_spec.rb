# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Revoke, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:recipient) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }
  let_it_be(:user_achievement) { create(:user_achievement, achievement: achievement) }

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        user_achievement_id: user_achievement&.to_global_id
      )
    end

    before_all do
      group.add_developer(developer)
      group.add_maintainer(maintainer)
    end

    context 'when the user does not have permission' do
      let(:current_user) { developer }

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'when the user has permission' do
      let(:current_user) { maintainer }

      context 'when the params are invalid' do
        let(:user_achievement) { nil }

        it 'returns the validation error' do
          expect { resolve_mutation }.to raise_error { Gitlab::Graphql::Errors::ArgumentError }
        end
      end

      it 'revokes  user_achievement' do
        response = resolve_mutation[:user_achievement]

        expect(response.revoked_at).not_to be_nil
        expect(response.revoked_by_user_id).to be(current_user.id)
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:award_achievement) }
end
