# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Organizations::Create do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :crm_enabled) }

  let(:valid_params) do
    attributes_for(:crm_organization,
      group: group,
      description: 'This company is super important!',
      default_rate: 1_000
    )
  end

  describe 'create organizations mutation' do
    describe '#resolve' do
      subject(:resolve_mutation) do
        described_class.new(object: nil, context: { current_user: user }, field: nil).resolve(
          **valid_params,
          group_id: group.to_global_id
        )
      end

      context 'when the user does not have permission' do
        before do
          group.add_reporter(user)
        end

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
            .with_message(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
        end
      end

      context 'when the user has permission' do
        before_all do
          group.add_developer(user)
        end

        context 'when the params are invalid' do
          before do
            valid_params[:name] = nil
          end

          it 'returns the validation error' do
            expect(resolve_mutation[:errors]).to eq(["Name can't be blank"])
          end
        end

        context 'when the user has permission to create an organization' do
          it 'creates organization with correct values' do
            expect(resolve_mutation[:organization]).to have_attributes(valid_params)
          end
        end
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_crm_organization) }
end
