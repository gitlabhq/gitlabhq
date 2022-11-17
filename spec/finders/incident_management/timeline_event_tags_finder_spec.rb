# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTagsFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident, occurred_at: Time.current)
  end

  let_it_be(:timeline_event_tag) do
    create(:incident_management_timeline_event_tag, project: project)
  end

  let_it_be(:timeline_event_tag_link) do
    create(:incident_management_timeline_event_tag_link,
      timeline_event: timeline_event,
      timeline_event_tag: timeline_event_tag)
  end

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(user, timeline_event, params).execute }

    context 'when user has permissions' do
      before do
        project.add_guest(user)
      end

      it 'returns tags on the event' do
        is_expected.to match_array([timeline_event_tag])
      end

      context 'when event does not have tags' do
        let(:timeline_event) do
          create(:incident_management_timeline_event, project: project, incident: incident, occurred_at: Time.current)
        end

        it 'returns empty result' do
          is_expected.to match_array([])
        end
      end

      context 'when timeline event is nil' do
        let(:timeline_event) { nil }

        it { is_expected.to eq(IncidentManagement::TimelineEventTag.none) }
      end
    end

    context 'when user does not have permissions' do
      it { is_expected.to eq(IncidentManagement::TimelineEventTag.none) }
    end
  end
end
