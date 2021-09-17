# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Organizations::Update do
  let_it_be(:user) { create(:user) }
  let_it_be(:name) { 'GitLab' }
  let_it_be(:default_rate) { 1000.to_f }
  let_it_be(:description) { 'VIP' }

  let(:organization) { create(:organization, group: group) }
  let(:attributes) do
    {
      id: organization.to_global_id,
      name: name,
      default_rate: default_rate,
      description: description
    }
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: { current_user: user }, field: nil).resolve(
        attributes
      )
    end

    context 'when the user does not have permission to update an organization' do
      let_it_be(:group) { create(:group) }

      before do
        group.add_guest(user)
      end

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the organization does not exist' do
      let_it_be(:group) { create(:group) }

      it 'raises an error' do
        attributes[:id] = 'gid://gitlab/CustomerRelations::Organization/999'

        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user has permission to update an organization' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_reporter(user)
      end

      it 'updates the organization with correct values' do
        expect(resolve_mutation[:organization]).to have_attributes(attributes)
      end

      context 'when the feature is disabled' do
        before do
          stub_feature_flags(customer_relations: false)
        end

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_organization) }
end
