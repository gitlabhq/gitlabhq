# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Create, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:group) { create(:group) }
  let(:valid_params) do
    attributes_for(:achievement, namespace: group)
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        **valid_params,
        namespace_id: group.to_global_id
      )
    end

    context 'when the user does not have permission' do
      before do
        group.add_developer(current_user)
      end

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'when the user has permission' do
      before do
        group.add_maintainer(current_user)
      end

      context 'when the params are invalid' do
        it 'returns the validation error' do
          valid_params[:name] = nil

          expect(resolve_mutation[:errors]).to match_array(["Name can't be blank"])
        end
      end

      it 'creates contact with correct values' do
        expect(resolve_mutation[:achievement]).to have_attributes(valid_params)
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_achievement) }
end
