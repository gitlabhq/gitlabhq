# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetWip do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:wip) { true }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, wip: wip) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'returns the merge request as a wip' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request).to be_work_in_progress
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing wip as false' do
        let(:wip) { false }

        it 'removes `wip` from the title' do
          merge_request.update(title: "WIP: working on it")

          expect(mutated_merge_request).not_to be_work_in_progress
        end

        it 'does not do anything if the title did not start with wip' do
          expect(mutated_merge_request).not_to be_work_in_progress
        end
      end
    end
  end
end
