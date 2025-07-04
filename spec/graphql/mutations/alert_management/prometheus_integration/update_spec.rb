# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::PrometheusIntegration::Update, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:old_integration) { create(:prometheus_integration, project: project) }
  let_it_be_with_reload(:integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }

  let(:args) { { id: GitlabSchema.id_from_object(old_integration), active: false, api_url: 'http://new-url.com' } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_operations) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has sufficient access to project' do
      before do
        project.add_maintainer(current_user)
      end

      context 'when ::AlertManagement::HttpIntegrations::UpdateService responds with success' do
        it 'returns the integration with no errors' do
          expect(resolve).to eq(
            integration: integration,
            errors: []
          )
          expect(integration.reload.active?).to be(false)
        end
      end

      context 'when ::AlertManagement::HttpIntegrations::UpdateService responds with an error' do
        before do
          allow_any_instance_of(::AlertManagement::HttpIntegrations::UpdateService)
            .to receive(:execute)
            .and_return(ServiceResponse.error(payload: { integration: nil }, message: 'An error occurred'))
        end

        it 'returns errors' do
          expect(resolve).to eq(
            integration: nil,
            errors: ['An error occurred']
          )
        end
      end

      context 'when prometheus_integration does not exist' do
        before do
          old_integration.destroy!
        end

        it 'raises an error if the resource is not accessible to the user' do
          expect(args[:id]).to be_present

          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when prometheus_integration does not have corresponding AlertManagement::HttpIntegration' do
        before do
          integration.destroy!
        end

        it 'raises an error if the resource is not accessible to the user' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
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
