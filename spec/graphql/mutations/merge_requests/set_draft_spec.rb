# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetDraft do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    let(:draft) { true }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, draft: draft) }

    it_behaves_like 'permission level for merge request mutation is correctly verified'

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'returns the merge request as a draft' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request).to be_draft
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors if/when merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing draft as false' do
        let(:draft) { false }

        it 'removes `Draft` from the title' do
          merge_request.update!(title: "Draft: working on it")

          expect(mutated_merge_request).not_to be_draft
        end

        it 'does not do anything if the title did not start with draft' do
          expect(mutated_merge_request).not_to be_draft
        end
      end
    end
  end
end
