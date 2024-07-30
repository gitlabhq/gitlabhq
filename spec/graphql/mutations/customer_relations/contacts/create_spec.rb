# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Contacts::Create do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:group) { create(:group) }
  let(:not_found_or_does_not_belong) { 'The specified organization was not found or does not belong to this group' }
  let(:valid_params) do
    attributes_for(:contact,
      group: group,
      description: 'Managing Director'
    )
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        **valid_params,
        group_id: group.to_global_id
      )
    end

    context 'when the user does not have permission' do
      before do
        group.add_reporter(current_user)
      end

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'when the user has permission' do
      before do
        group.add_developer(current_user)
      end

      context 'when crm_enabled is false' do
        let(:group) { create(:group, :crm_disabled) }

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
            .with_message("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
        end
      end

      context 'when the params are invalid' do
        it 'returns the validation error' do
          valid_params[:first_name] = nil

          expect(resolve_mutation[:errors]).to match_array(["First name can't be blank"])
        end
      end

      context 'when attaching to an crm_organization' do
        context 'when all ok' do
          before do
            organization = create(:crm_organization, group: group)
            valid_params[:organization_id] = organization.to_global_id
          end

          it 'creates contact with correct values' do
            expect(resolve_mutation[:contact].organization).to be_present
          end
        end

        context 'when crm_organization does not exist' do
          before do
            valid_params[:organization_id] = global_id_of(model_name: 'CustomerRelations::Organization', id: non_existing_record_id)
          end

          it 'returns the relevant error' do
            expect(resolve_mutation[:errors]).to match_array([not_found_or_does_not_belong])
          end
        end

        context 'when crm_organzation belongs to a different group' do
          before do
            crm_organization = create(:crm_organization)
            valid_params[:organization_id] = crm_organization.to_global_id
          end

          it 'returns the relevant error' do
            expect(resolve_mutation[:errors]).to match_array([not_found_or_does_not_belong])
          end
        end
      end

      it 'creates contact with correct values' do
        expect(resolve_mutation[:contact]).to have_attributes(valid_params)
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_crm_contact) }
end
