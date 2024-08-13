# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetReviewers, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request) }
  let_it_be(:reviewer) { create(:user) }
  let_it_be(:reviewer2) { create(:user) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  describe '#resolve' do
    let(:reviewer_usernames) { [reviewer.username] }
    let(:mutated_merge_request) { subject[:merge_request] }
    let(:mode) { described_class.arguments['operationMode'].default_value }

    subject do
      mutation.resolve(
        project_path: merge_request.project.full_path,
        iid: merge_request.iid,
        operation_mode: mode,
        reviewer_usernames: reviewer_usernames
      )
    end

    it 'does not change reviewers if the merge_request is not accessible to the reviewers' do
      merge_request.project.add_developer(user)

      expect { subject }.not_to change { merge_request.reload.reviewer_ids }
    end

    it 'returns an operational error if the merge_request is not accessible to the reviewers' do
      merge_request.project.add_developer(user)

      result = subject

      expect(result[:errors]).to include a_string_matching(/Cannot assign/)
    end

    context 'when the user does not have permissions' do
      it_behaves_like 'permission level for merge request mutation is correctly verified'
    end

    context 'when the user can update the merge_request' do
      before do
        merge_request.project.add_developer(reviewer)
        merge_request.project.add_developer(reviewer2)
        merge_request.project.add_developer(user)
      end

      it 'replaces the reviewer' do
        merge_request.reviewers = [reviewer2]
        merge_request.save!

        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.reviewers).to contain_exactly(reviewer)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors when merge_request could not be updated' do
        allow(merge_request).to receive(:errors_on_object).and_return(['foo'])

        expect(subject[:errors]).not_to match_array(['foo'])
      end

      context 'when passing an empty reviewer list' do
        let(:reviewer_usernames) { [] }

        before do
          merge_request.reviewers = [reviewer]
          merge_request.save!
        end

        it 'removes all reviewers' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.reviewers).to eq([])
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "append" as true' do
        subject do
          mutation.resolve(
            project_path: merge_request.project.full_path,
            iid: merge_request.iid,
            reviewer_usernames: reviewer_usernames,
            operation_mode: Types::MutationOperationModeEnum.enum[:append]
          )
        end

        before do
          merge_request.reviewers = [reviewer2]
          merge_request.save!

          # In CE, APPEND is a NOOP as you can't have multiple reviewers
          # We test multiple assignment in EE specs
          stub_licensed_features(multiple_merge_request_reviewers: false)
        end

        it 'is a NO-OP in FOSS' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.reviewers).to contain_exactly(reviewer2)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "remove" as true' do
        before do
          merge_request.reviewers = [reviewer]
          merge_request.save!
        end

        it 'removes named reviewer' do
          mutated_merge_request = mutation.resolve(
            project_path: merge_request.project.full_path,
            iid: merge_request.iid,
            reviewer_usernames: reviewer_usernames,
            operation_mode: Types::MutationOperationModeEnum.enum[:remove]
          )[:merge_request]

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.reviewers).to eq([])
          expect(subject[:errors]).to be_empty
        end

        it 'does not remove unnamed reviewer' do
          mutated_merge_request = mutation.resolve(
            project_path: merge_request.project.full_path,
            iid: merge_request.iid,
            reviewer_usernames: [reviewer2.username],
            operation_mode: Types::MutationOperationModeEnum.enum[:remove]
          )[:merge_request]

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.reviewers).to contain_exactly(reviewer)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
