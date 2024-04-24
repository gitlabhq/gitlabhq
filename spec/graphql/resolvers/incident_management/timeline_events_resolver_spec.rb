# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::IncidentManagement::TimelineEventsResolver' do
  include GraphqlHelpers

  let_it_be(:described_class) { Resolvers::IncidentManagement::TimelineEventsResolver }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, guests: current_user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:first_timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident)
  end

  let_it_be(:second_timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident)
  end

  let(:args) { { incident_id: incident.to_global_id } }
  let(:resolver) { described_class }

  subject(:resolved_timeline_events) { sync(resolve_timeline_events(args, current_user: current_user).to_a) }

  specify do
    expect(resolver).to have_nullable_graphql_type(Types::IncidentManagement::TimelineEventType.connection_type)
  end

  it 'returns timeline events', :aggregate_failures do
    expect(resolved_timeline_events.length).to eq(2)
    expect(resolved_timeline_events.first).to be_a(::IncidentManagement::TimelineEvent)
  end

  context 'when user does not have permissions' do
    let(:non_member) { create(:user) }

    subject(:resolved_timeline_events) { sync(resolve_timeline_events(args, current_user: non_member).to_a) }

    before do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
    end

    it 'returns no timeline events' do
      expect(resolved_timeline_events.length).to eq(0)
    end
  end

  context 'when resolving a single item' do
    let(:resolver) { described_class.single }

    subject(:resolved_timeline_event) { sync(resolve_timeline_events(args, current_user: current_user)) }

    context 'when id given' do
      let(:args) { { incident_id: incident.to_global_id, id: first_timeline_event.to_global_id } }

      it 'returns the timeline event' do
        expect(resolved_timeline_event).to eq(first_timeline_event)
      end
    end
  end

  private

  def resolve_timeline_events(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: incident, args: args, ctx: context)
  end
end
