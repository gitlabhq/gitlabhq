# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Contacts::Create do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group, :crm_enabled) }
  let(:not_found_or_does_not_belong) { 'The specified organization was not found or does not belong to this group' }
  let(:valid_params) do
    attributes_for(:contact,
      group: group,
      description: 'Managing Director'
    )
  end

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
      before do
        group.add_developer(user)
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(customer_relations: false)
        end

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
            .with_message("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
        end
      end

      context 'when crm_enabled is false' do
        let(:group) { create(:group) }

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

      context 'when attaching to an organization' do
        context 'when all ok' do
          before do
            organization = create(:organization, group: group)
            valid_params[:organization_id] = organization.to_global_id
          end

          it 'creates contact with correct values' do
            expect(resolve_mutation[:contact].organization).to be_present
          end
        end

        context 'when organization_id is invalid' do
          before do
            valid_params[:organization_id] = "gid://gitlab/CustomerRelations::Organization/#{non_existing_record_id}"
          end

          it 'returns the relevant error' do
            expect(resolve_mutation[:errors]).to match_array([not_found_or_does_not_belong])
          end
        end

        context 'when organzation belongs to a different group' do
          before do
            organization = create(:organization)
            valid_params[:organization_id] = organization.to_global_id
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
