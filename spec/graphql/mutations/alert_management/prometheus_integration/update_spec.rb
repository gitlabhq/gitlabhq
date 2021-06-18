# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::PrometheusIntegration::Update do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:integration) { create(:prometheus_integration, project: project) }

  let(:args) { { id: GitlabSchema.id_from_object(integration), active: false, api_url: 'http://new-url.com' } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has sufficient access to project' do
      before do
        project.add_maintainer(current_user)
      end

      context 'when ::Projects::Operations::UpdateService responds with success' do
        it 'returns the integration with no errors' do
          expect(resolve).to eq(
            integration: integration,
            errors: []
          )
        end
      end

      context 'when ::Projects::Operations::UpdateService responds with an error' do
        before do
          allow_any_instance_of(::Projects::Operations::UpdateService)
            .to receive(:execute)
            .and_return({ status: :error, message: 'An error occurred' })
        end

        it 'returns errors' do
          expect(resolve).to eq(
            integration: integration,
            errors: ['An error occurred']
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

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
