# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetMilestone do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:milestone) { create(:milestone, project: merge_request.project) }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, milestone: milestone) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'returns the merge request with the milestone' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.milestone).to eq(milestone)
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
          merge_request.update!(milestone: create(:milestone, project: merge_request.project))

          expect(mutated_merge_request.milestone).to eq(nil)
        end

        it 'does not do anything if the MR already does not have a milestone' do
          expect(mutated_merge_request.milestone).to eq(nil)
        end
      end
    end
  end
end
