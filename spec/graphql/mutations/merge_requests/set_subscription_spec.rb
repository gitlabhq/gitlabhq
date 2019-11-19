# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetSubscription do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { create(:user) }
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:subscribe) { true }
    let(:mutated_merge_request) { subject[:merge_request] }
    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, subscribed_state: subscribe) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'returns the merge request as discussion locked' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.subscribed?(user, project)).to eq(true)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing subscribe as false' do
        let(:subscribe) { false }

        it 'unsubscribes from the discussion' do
          merge_request.subscribe(user, project)

          expect(mutated_merge_request.subscribed?(user, project)).to eq(false)
        end
      end
    end
  end
end
