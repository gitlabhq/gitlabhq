# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetMilestone, feature_category: :api do
  include GraphqlHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :private) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project, assignees: [user]) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }
  let(:mutation) { described_class.new(object: nil, context: context, field: nil) }
  let(:milestone) { create(:milestone, project: project) }

  subject { mutation.resolve(project_path: project.full_path, iid: merge_request.iid, milestone: milestone) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    it_behaves_like 'permission level for merge request mutation is correctly verified'

    context 'when the user can update the merge request' do
      before do
        project.add_developer(user)
      end

      it 'returns the merge request with the milestone' do
        expect(subject[:merge_request]).to eq(merge_request)
        expect(subject[:merge_request].milestone).to eq(milestone)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing milestone_id as nil' do
        let(:milestone) { nil }

        it 'removes the milestone' do
          merge_request.update!(milestone: create(:milestone, project: project))

          expect(subject[:merge_request].milestone).to be_nil
        end

        it 'does not do anything if the MR already does not have a milestone' do
          expect(subject[:merge_request].milestone).to be_nil
        end
      end
    end

    context 'when issue assignee is a guest' do
      let(:project) { create(:project, :public) }

      before do
        project.add_guest(user)
      end

      it 'does not update the milestone' do
        expect(subject[:merge_request]).to eq(merge_request)
        expect(subject[:merge_request].milestone).to be_nil
        expect(subject[:errors]).to be_empty
      end

      context 'when passing milestone_id as nil' do
        let(:milestone) { nil }

        it 'does not remove the milestone' do
          merge_request.update!(milestone: create(:milestone, project: project))

          expect(subject[:merge_request].milestone).not_to be_nil
        end
      end
    end
  end
end
