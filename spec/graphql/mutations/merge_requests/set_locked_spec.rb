# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetLocked, feature_category: :api do
  include GraphqlHelpers

  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    let(:locked) { true }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, locked: locked) }

    it_behaves_like 'permission level for merge request mutation is correctly verified'

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'returns the merge request as discussion locked' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request).to be_discussion_locked
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing locked as false' do
        let(:locked) { false }

        it 'unlocks the discussion' do
          merge_request.update!(discussion_locked: true)

          expect(mutated_merge_request).not_to be_discussion_locked
        end
      end
    end
  end
end
