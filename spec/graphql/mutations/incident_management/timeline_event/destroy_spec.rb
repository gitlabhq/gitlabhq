# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::Destroy, feature_category: :api do
  include GraphqlHelpers
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let(:timeline_event) { create(:incident_management_timeline_event, incident: incident, project: project) }
  let(:args) { { id: timeline_event.to_global_id } }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: current_user }) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(**args) }

    context 'when a user has permissions to delete timeline event' do
      before do
        project.add_developer(current_user)
      end

      context 'when TimelineEvents::DestroyService responds with success' do
        it 'returns the timeline event with no errors' do
          expect(resolve).to eq(
            timeline_event: timeline_event,
            errors: []
          )
        end
      end

      context 'when TimelineEvents::DestroyService responds with an error' do
        before do
          allow_next_instance_of(::IncidentManagement::TimelineEvents::DestroyService) do |service|
            allow(service)
              .to receive(:execute)
              .and_return(ServiceResponse.error(payload: { timeline_event: nil }, message: 'An error has occurred'))
          end
        end

        it 'returns errors' do
          expect(resolve).to eq(
            timeline_event: nil,
            errors: ['An error has occurred']
          )
        end
      end
    end

    context 'when a user has no permissions to delete timeline event' do
      before do
        project.add_guest(current_user)
      end

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  private

  def mutation_for(project, _user)
    described_class.new(object: project, context: context, field: nil)
  end
end
