# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::PromoteFromNote, feature_category: :api do
  include GraphqlHelpers
  include NotesHelper

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:comment) { create(:note, project: project, noteable: incident) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue_comment) { create(:note, project: project, noteable: issue) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }
  let_it_be(:alert_comment) { create(:note, project: project, noteable: alert) }

  let(:args) { { note_id: comment.to_global_id.to_s } }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: current_user }) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(**args) }

    context 'when a user has permissions to create timeline event' do
      let(:expected_timeline_event) do
        instance_double(
          'IncidentManagement::TimelineEvent',
          note: "@#{comment.author.username} [commented](#{noteable_note_url(comment)}): '#{comment.note}'",
          occurred_at: comment.created_at.to_s,
          incident: incident,
          author: current_user,
          promoted_from_note: comment,
          editable: true
        )
      end

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'creating an incident timeline event'

      context 'when TimelineEvents::CreateService responds with an error' do
        before do
          allow_next_instance_of(::IncidentManagement::TimelineEvents::CreateService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(payload: { timeline_event: nil }, message: 'Some error')
            )
          end
        end

        it_behaves_like 'responding with an incident timeline errors', errors: ['Some error']
      end
    end

    context 'when note does not exist' do
      let(:args) { { note_id: 'gid://gitlab/Note/0' } }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when note does not belong to an incident' do
      let(:args) { { note_id: issue_comment.to_global_id.to_s } }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when note belongs to anything else but issuable' do
      let(:args) { { note_id: alert_comment.to_global_id.to_s } }

      it 'raises an error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    it_behaves_like 'failing to create an incident timeline event'
  end

  private

  def mutation_for(project, _user)
    described_class.new(object: project, context: context, field: nil)
  end
end
