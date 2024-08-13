# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::UpdateAlertStatus, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, :triggered) }
  let_it_be(:project) { alert.project }

  let(:new_status) { Types::AlertManagement::StatusEnum.values['ACKNOWLEDGED'].value }
  let(:args) { { status: new_status, project_path: project.full_path, iid: alert.iid } }

  specify { expect(described_class).to require_graphql_authorizations(:update_alert_management_alert) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(**args) }

    context 'user has access to project' do
      before do
        project.add_developer(current_user)
      end

      it 'changes the status' do
        expect { resolve }.to change { alert.reload.acknowledged? }.to(true)
      end

      it 'returns the alert with no errors' do
        expect(resolve).to eq(
          alert: alert,
          errors: []
        )
      end

      it_behaves_like 'an incident management tracked event', :incident_management_alert_status_changed do
        let(:user) { current_user }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace }
        let(:category) { described_class.to_s }
        let(:user) { current_user }
        let(:action) { 'incident_management_alert_status_changed' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end

      context 'error occurs when updating' do
        it 'returns the alert with errors' do
          # Stub an error on the alert
          allow_next_instance_of(::AlertManagement::AlertsFinder) do |finder|
            allow(finder).to receive(:execute).and_return([alert])
          end

          allow(alert).to receive(:save).and_return(false)
          allow(alert).to receive(:errors).and_return(
            double(full_messages: %w[foo bar], :[] => nil)
          )
          expect(resolve).to eq(
            alert: alert,
            errors: ['foo and bar']
          )
        end

        context 'invalid status given' do
          let(:new_status) { 'invalid_status' }

          it 'returns the alert with errors' do
            expect(resolve).to eq(
              alert: alert,
              errors: [_('Invalid status')]
            )
          end
        end
      end
    end

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  private

  def mutation_for(project, _user)
    described_class.new(object: project, context: query_context, field: nil)
  end
end
