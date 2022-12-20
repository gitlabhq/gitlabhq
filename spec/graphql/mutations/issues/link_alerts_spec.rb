# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::LinkAlerts, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:issue) { create(:incident, project: project) }
  let_it_be(:alert1) { create(:alert_management_alert, project: project) }
  let_it_be(:alert2) { create(:alert_management_alert, project: project) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue, :admin_issue) }

  before_all do
    project.add_guest(guest)
    project.add_developer(developer)
  end

  describe '#resolve' do
    let(:alert_references) { [alert1.to_reference, alert2.details_url, 'invalid-reference'] }

    subject(:resolve) do
      mutation.resolve(
        project_path: issue.project.full_path,
        iid: issue.iid,
        alert_references: alert_references
      )
    end

    context 'when the user is a guest' do
      let(:user) { guest }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end

      context 'when a user is also an author' do
        let!(:issue) { create(:incident, project: project, author: user) }

        it 'raises an error' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when a user is also an assignee' do
        let!(:issue) { create(:incident, project: project, assignee_ids: [user.id]) }

        it 'raises an error' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when the user is a developer' do
      let(:user) { developer }

      context 'when issue type is an incident' do
        it 'calls LinkAlerts::CreateService with correct arguments' do
          expect(::IncidentManagement::LinkAlerts::CreateService)
            .to receive(:new)
            .with(issue, user, alert_references)
            .and_call_original

          resolve
        end

        it 'returns no errors' do
          expect(resolve[:errors]).to be_empty
        end
      end

      context 'when issue type is not an incident' do
        let!(:issue) { create(:issue, project: project) }

        it 'does not update alert_management_alerts' do
          expect { resolve }.not_to change { issue.alert_management_alerts }
        end
      end
    end
  end
end
