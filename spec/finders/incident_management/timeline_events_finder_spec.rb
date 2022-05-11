# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventsFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:another_incident) { create(:incident, project: project) }

  let_it_be(:timeline_event1) do
    create(:incident_management_timeline_event, project: project, incident: incident, occurred_at: Time.current)
  end

  let_it_be(:timeline_event2) do
    create(:incident_management_timeline_event, project: project, incident: incident, occurred_at: 1.minute.ago)
  end

  let_it_be(:timeline_event_of_another_incident) do
    create(:incident_management_timeline_event, project: project, incident: another_incident)
  end

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(user, incident, params).execute }

    context 'when user has permissions' do
      before do
        project.add_guest(user)
      end

      it 'returns timeline events' do
        is_expected.to match_array([timeline_event2, timeline_event1])
      end

      context 'when filtering by ID' do
        let(:params) { { id: timeline_event1 } }

        it 'returns only matched timeline event' do
          is_expected.to contain_exactly(timeline_event1)
        end
      end

      context 'when incident is nil' do
        let_it_be(:incident) { nil }

        it { is_expected.to eq(IncidentManagement::TimelineEvent.none) }
      end
    end

    context 'when user has no permissions' do
      it { is_expected.to eq(IncidentManagement::TimelineEvent.none) }
    end
  end
end
