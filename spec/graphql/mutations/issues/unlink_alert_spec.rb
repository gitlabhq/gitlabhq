# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::UnlinkAlert, feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:internal_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:external_alert) { create(:alert_management_alert, project: another_project) }
  let_it_be(:issue) { create(:incident, project: project, alert_management_alerts: [internal_alert, external_alert]) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue, :admin_issue) }

  describe '#resolve' do
    let(:alert_to_unlink) { internal_alert }

    subject(:resolve) do
      mutation.resolve(
        project_path: issue.project.full_path,
        iid: issue.iid,
        alert_id: alert_to_unlink.to_global_id.to_s
      )
    end

    context 'when the user is a guest' do
      let(:current_user) { guest }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user is a developer' do
      let(:current_user) { developer }

      shared_examples 'unlinking an alert' do
        it 'unlinks the alert' do
          expect { resolve }.to change { issue.reload.alert_management_alerts }.to match_array(remainded_alerts)
        end

        it 'returns no errors' do
          expect(resolve[:errors]).to be_empty
        end
      end

      context 'when unlinking internal alert' do
        let(:alert_to_unlink) { internal_alert }
        let(:remainded_alerts) { [external_alert] }

        it_behaves_like 'unlinking an alert'
      end

      context 'when unlinking external alert' do
        let(:alert_to_unlink) { external_alert }
        let(:remainded_alerts) { [internal_alert] }

        it_behaves_like 'unlinking an alert'
      end

      context 'when LinkAlerts::DestroyService responds with an error' do
        it 'returns the error' do
          service_instance = instance_double(
            ::IncidentManagement::LinkAlerts::DestroyService,
            execute: ServiceResponse.error(message: 'some error message')
          )

          allow(::IncidentManagement::LinkAlerts::DestroyService).to receive(:new).and_return(service_instance)

          expect(resolve[:errors]).to match_array(['some error message'])
        end
      end
    end
  end
end
