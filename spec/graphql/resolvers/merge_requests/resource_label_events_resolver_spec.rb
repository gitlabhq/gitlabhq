# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequests::ResourceLabelEventsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:other_label) { create(:label, project: project) }

  let_it_be(:label_event) { create(:resource_label_event, merge_request: merge_request, label: label) }
  let_it_be(:other_label_event) { create(:resource_label_event, merge_request: merge_request, label: other_label) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::MergeRequests::ResourceLabelEventType.connection_type)
  end

  def resolve_events(args = {})
    resolve(described_class, obj: merge_request, args: args, ctx: { current_user: current_user })
  end

  describe '#resolve' do
    context 'without the labelId argument' do
      it 'returns every label event for the merge request' do
        expect(resolve_events).to contain_exactly(label_event, other_label_event)
      end
    end

    context 'with the labelId argument' do
      it 'returns only the events for the given label' do
        expect(resolve_events(label_id: global_id_of(label))).to contain_exactly(label_event)
      end
    end

    context 'when the labelId argument is null' do
      it 'returns every label event for the merge request' do
        expect(resolve_events(label_id: nil)).to contain_exactly(label_event, other_label_event)
      end
    end
  end
end
