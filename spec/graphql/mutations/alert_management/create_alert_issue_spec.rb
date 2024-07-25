# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::CreateAlertIssue, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project, status: 'triggered') }

  let(:args) { { project_path: project.full_path, iid: alert.iid } }

  specify { expect(described_class).to require_graphql_authorizations(:update_alert_management_alert) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_developer(current_user)
      end

      context 'when CreateAlertIssueService responds with success' do
        it 'returns the issue with no errors' do
          expect(resolve).to eq(
            alert: alert.reload,
            issue: Issue.last!,
            errors: []
          )
        end

        it_behaves_like 'an incident management tracked event', :incident_management_incident_created
        it_behaves_like 'an incident management tracked event', :incident_management_alert_create_incident

        it_behaves_like 'Snowplow event tracking with RedisHLL context' do
          let(:namespace) { project.namespace.reload }
          let(:category) { described_class.to_s }
          let(:user) { current_user }
          let(:action) { 'incident_management_incident_created' }
          let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
        end
      end

      context 'when CreateAlertIssue responds with an error' do
        before do
          allow_any_instance_of(::AlertManagement::CreateAlertIssueService)
            .to receive(:execute)
            .and_return(ServiceResponse.error(payload: { issue: nil }, message: 'An issue already exists'))
        end

        it 'returns errors' do
          expect(resolve).to eq(
            alert: alert,
            issue: nil,
            errors: ['An issue already exists']
          )
        end

        it_behaves_like 'Snowplow event tracking with RedisHLL context' do
          let(:namespace) { project.namespace.reload }
          let(:category) { described_class.to_s }
          let(:user) { current_user }
          let(:action) { 'incident_management_incident_created' }
          let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
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
