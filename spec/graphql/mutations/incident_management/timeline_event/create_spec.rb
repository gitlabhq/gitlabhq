# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::Create, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:timeline_event_tag) do
    create(:incident_management_timeline_event_tag, project: project, name: 'Test tag 1')
  end

  let(:args) { { note: 'note', occurred_at: Time.current } }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: current_user }) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(incident_id: incident.to_global_id, **args) }

    context 'when a user has permissions to create a timeline event' do
      let(:expected_timeline_event) do
        instance_double(
          'IncidentManagement::TimelineEvent',
          note: args[:note],
          occurred_at: args[:occurred_at].to_s,
          incident: incident,
          author: current_user,
          promoted_from_note: nil,
          editable: true
        )
      end

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'creating an incident timeline event'

      context 'when TimelineEvents::CreateService responds with an error' do
        let(:args) { {} }

        it_behaves_like 'responding with an incident timeline errors',
          errors: ["Occurred at can't be blank and Timeline text can't be blank"]
      end

      context 'when timeline event tags are passed' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: [timeline_event_tag.name.to_s]
          }
        end

        it_behaves_like 'creating an incident timeline event'
      end

      context 'when predefined tags are passed' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: ['Start time']
          }
        end

        it_behaves_like 'creating an incident timeline event'

        it 'creates and sets the tag on the event' do
          timeline_event = resolve[:timeline_event]

          expect(timeline_event.timeline_event_tags.by_names(['Start time']).count).to eq 1
        end
      end

      context 'when predefined tags exist' do
        let_it_be(:end_time_tag) do
          create(:incident_management_timeline_event_tag, project: project, name: 'End time')
        end

        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: ['End time']
          }
        end

        it 'does not create a new tag' do
          expect { resolve }.not_to change(IncidentManagement::TimelineEventTag, :count)
        end
      end

      context 'when same tags are tried to be assigned to same timeline event' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: ['Start time', 'Start time']
          }
        end

        it 'only assigns the tag once on the event' do
          timeline_event = resolve[:timeline_event]

          expect(timeline_event.timeline_event_tags.by_names(['Start time']).count).to eq(1)
          expect(timeline_event.timeline_event_tags.count).to eq(1)
        end
      end

      context 'with case-insentive tags' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: ['tESt tAg 1']
          }
        end

        it 'sets the tag on the event' do
          timeline_event = resolve[:timeline_event]

          expect(timeline_event.timeline_event_tags.by_names(['Test tag 1']).count).to eq(1)
        end
      end

      context 'when non-existing tags are passed' do
        let(:args) do
          {
            note: 'note',
            occurred_at: Time.current,
            timeline_event_tag_names: ['other time']
          }
        end

        it_behaves_like 'responding with an incident timeline errors',
          errors: ["Following tags don't exist: [\"other time\"]"]

        it 'does not create the timeline event' do
          expect { resolve }.not_to change(IncidentManagement::TimelineEvent, :count)
        end
      end
    end

    it_behaves_like 'failing to create an incident timeline event'
  end

  private

  def mutation_for(project, _user)
    described_class.new(object: project, context: context, field: nil)
  end
end
