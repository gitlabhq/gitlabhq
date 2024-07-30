# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Organizations::Update do
  include GraphqlHelpers
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:name) { 'GitLab' }
  let(:default_rate) { 1000.to_f }
  let(:description) { 'VIP' }
  let(:does_not_exist_or_no_permission) { Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR }
  let(:crm_organization) { create(:crm_organization, group: group) }
  let(:attributes) do
    {
      id: crm_organization.to_global_id,
      name: name,
      default_rate: default_rate,
      description: description
    }
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        attributes
      )
    end

    context 'when the user does not have permission to update an crm_organization' do
      before do
        group.add_reporter(current_user)
      end

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(does_not_exist_or_no_permission)
      end
    end

    context 'when the crm_organization does not exist' do
      it 'raises an error' do
        attributes[:id] = "gid://gitlab/CustomerRelations::Organization/#{non_existing_record_id}"

        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(does_not_exist_or_no_permission)
      end
    end

    context 'when the user has permission to update an crm_organization' do
      before_all do
        group.add_developer(current_user)
      end

      it 'updates the crm_organization with correct values' do
        expect(resolve_mutation[:organization]).to have_attributes(attributes)
      end

      context 'when the feature is disabled' do
        let_it_be(:group) { create(:group) }

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
            .with_message("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
        end
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_crm_organization) }
end
