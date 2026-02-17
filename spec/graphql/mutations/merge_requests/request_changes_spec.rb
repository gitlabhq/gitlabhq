# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::RequestChanges, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    subject(:resolve_mutation) do
      mutation.resolve(
        project_path: merge_request.project.full_path,
        iid: merge_request.iid.to_s
      )
    end

    it_behaves_like 'permission level for merge request mutation is correctly verified' do
      subject { resolve_mutation }
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
        merge_request.reviewers = [user]
      end

      it 'returns the merge request' do
        expect(resolve_mutation[:merge_request]).to eq(merge_request)
        expect(resolve_mutation[:errors]).to be_empty
      end

      it 'updates the reviewer state to requested_changes' do
        resolve_mutation

        reviewer = merge_request.reload.merge_request_reviewers.find_by(user_id: user.id)
        expect(reviewer.state).to eq('requested_changes')
      end

      it 'creates a system note' do
        expect { resolve_mutation }.to change { merge_request.notes.count }.by(1)
        expect(merge_request.notes.last.note).to include('requested changes')
      end

      context 'when the user is not a reviewer' do
        let(:non_reviewer) { create(:user) }
        let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: non_reviewer }) }

        before do
          merge_request.project.add_developer(non_reviewer)
        end

        it 'returns an error' do
          expect(resolve_mutation[:errors]).to include('Reviewer not found')
        end
      end
    end
  end
end
