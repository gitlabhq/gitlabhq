# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::PrometheusIntegration::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:args) { { project_path: project.full_path, active: true, api_url: 'http://prometheus.com/' } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_maintainer(current_user)
      end

      context 'when Prometheus Integration already exists' do
        let_it_be(:existing_integration) { create(:prometheus_integration, project: project) }

        it 'returns errors' do
          expect(resolve).to eq(
            integration: nil,
            errors: ['Multiple Prometheus integrations are not supported']
          )
        end
      end

      context 'when UpdateService responds with success' do
        it 'returns the integration with no errors' do
          expect(resolve).to eq(
            integration: ::Integrations::Prometheus.last!,
            errors: []
          )
        end

        it 'creates a corresponding token' do
          expect { resolve }.to change(::Alerting::ProjectAlertingSetting, :count).by(1)
        end
      end

      context 'when UpdateService responds with an error' do
        before do
          allow_any_instance_of(::Projects::Operations::UpdateService)
            .to receive(:execute)
            .and_return({ status: :error, message: 'An error occurred' })
        end

        it 'returns errors' do
          expect(resolve).to eq(
            integration: nil,
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
