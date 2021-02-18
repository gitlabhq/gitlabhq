# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Update do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    let(:attributes) { { title: 'new title', description: 'new description', target_branch: 'new-branch' } }
    let(:arguments) { attributes }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject do
      mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, **arguments)
    end

    it_behaves_like 'permission level for merge request mutation is correctly verified'

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'applies all attributes' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request).to have_attributes(attributes)
        expect(subject[:errors]).to be_empty
      end

      context 'the merge request is invalid' do
        before do
          merge_request.allow_broken = true
          merge_request.update!(source_project: nil)
        end

        it 'returns error information, and changes were not applied' do
          expect(mutated_merge_request).not_to have_attributes(attributes)
          expect(subject[:errors]).not_to be_empty
        end
      end

      context 'our change is invalid' do
        let(:attributes) { { target_branch: 'this is not a branch' } }

        it 'returns error information, and changes were not applied' do
          expect(mutated_merge_request).not_to have_attributes(attributes)
          expect(subject[:errors]).not_to be_empty
        end
      end

      context 'when passing subset of attributes' do
        let(:attributes) { { title: 'no, this title' } }

        it 'only changes the mentioned attributes' do
          expect { subject }.not_to change { merge_request.reset.description }

          expect(mutated_merge_request).to have_attributes(attributes)
        end
      end

      context 'when closing the MR' do
        let(:arguments) { { state_event: ::Types::MergeRequestStateEventEnum.values['CLOSED'].value } }

        it 'closes the MR' do
          expect(mutated_merge_request).to be_closed
        end
      end

      context 'when re-opening the MR' do
        let(:arguments) { { state_event: ::Types::MergeRequestStateEventEnum.values['OPEN'].value } }

        it 'closes the MR' do
          merge_request.close!

          expect(mutated_merge_request).to be_open
        end
      end
    end
  end
end
