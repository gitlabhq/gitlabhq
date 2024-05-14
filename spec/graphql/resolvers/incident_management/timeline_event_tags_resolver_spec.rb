# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IncidentManagement::TimelineEventTagsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, guests: current_user) }
  let_it_be(:incident) { create(:incident, project: project) }

  let_it_be(:timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident)
  end

  let_it_be(:timeline_event_with_no_tags) do
    create(:incident_management_timeline_event, project: project, incident: incident)
  end

  let_it_be(:timeline_event_tag) do
    create(:incident_management_timeline_event_tag, project: project)
  end

  let_it_be(:timeline_event_tag2) do
    create(:incident_management_timeline_event_tag, project: project, name: 'Test tag 2')
  end

  let_it_be(:timeline_event_tag_link) do
    create(:incident_management_timeline_event_tag_link,
      timeline_event: timeline_event,
      timeline_event_tag: timeline_event_tag)
  end

  let(:resolver) { described_class }

  subject(:resolved_timeline_event_tags) do
    sync(resolve_timeline_event_tags(timeline_event, current_user: current_user).to_a)
  end

  specify do
    expect(resolver).to have_nullable_graphql_type(
      Types::IncidentManagement::TimelineEventTagType.connection_type
    )
  end

  it 'returns timeline event tags', :aggregate_failures do
    expect(resolved_timeline_event_tags.length).to eq(1)
    expect(resolved_timeline_event_tags.first).to be_a(::IncidentManagement::TimelineEventTag)
  end

  context 'when timeline event is nil' do
    subject(:resolved_timeline_event_tags) do
      sync(resolve_timeline_event_tags(nil, current_user: current_user).to_a)
    end

    it 'returns no timeline event tags' do
      expect(resolved_timeline_event_tags).to be_empty
    end
  end

  context 'when there is no timeline event tag link' do
    subject(:resolved_timeline_event_tags) do
      sync(resolve_timeline_event_tags(timeline_event_with_no_tags, current_user: current_user).to_a)
    end

    it 'returns no timeline event tags' do
      expect(resolved_timeline_event_tags).to be_empty
    end
  end

  context 'when user does not have permissions' do
    let(:non_member) { create(:user) }

    subject(:resolved_timeline_event_tags) do
      sync(resolve_timeline_event_tags(timeline_event, current_user: non_member).to_a)
    end

    it 'returns no timeline event tags' do
      expect(resolved_timeline_event_tags).to be_empty
    end
  end

  private

  def resolve_timeline_event_tags(obj, context = { current_user: current_user })
    resolve(resolver, obj: obj, args: {}, ctx: context, arg_style: :internal_prepared)
  end
end
