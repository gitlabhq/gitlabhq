# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Update, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:recipient) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:achievement) { create(:achievement, namespace: group) }
  let(:name) { 'Hero' }

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        achievement_id: achievement&.to_global_id, name: name
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
        let(:achievement) { nil }

        it 'returns the validation error' do
          expect { resolve_mutation }.to raise_error { Gitlab::Graphql::Errors::ArgumentError }
        end
      end

      it 'updates the achievement' do
        resolve_mutation

        expect(Achievements::Achievement.find_by(id: achievement.id).name).to eq(name)
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_achievement) }
end
