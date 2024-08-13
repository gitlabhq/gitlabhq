# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::HttpIntegration::Create, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:args) { { project_path: project.full_path, active: true, name: 'HTTP Integration' } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_operations) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_maintainer(current_user)
      end

      context 'when HttpIntegrations::CreateService responds with success' do
        it 'returns the integration with no errors' do
          expect(resolve).to eq(
            integration: ::AlertManagement::HttpIntegration.last!,
            errors: []
          )
        end
      end

      context 'when HttpIntegrations::CreateService responds with an error' do
        before do
          allow_any_instance_of(::AlertManagement::HttpIntegrations::CreateService)
            .to receive(:execute)
            .and_return(ServiceResponse.error(payload: { integration: nil }, message: 'An integration already exists'))
        end

        it 'returns errors' do
          expect(resolve).to eq(
            integration: nil,
            errors: ['An integration already exists']
          )
        end
      end
    end

    context 'when resource is not accessible to the user' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  private

  def mutation_for(project, _user)
    described_class.new(object: project, context: query_context, field: nil)
  end
end
