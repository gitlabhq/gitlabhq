# frozen_string_literal: true

require 'spec_helper'

describe Mutations::Issues::SetConfidential do
  let(:issue) { create(:issue) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:confidential) { true }
    let(:mutated_issue) { subject[:issue] }

    subject { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, confidential: confidential) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the issue' do
      before do
        issue.project.add_developer(user)
      end

      it 'returns the issue as confidential' do
        expect(mutated_issue).to eq(issue)
        expect(mutated_issue.confidential).to be_truthy
        expect(subject[:errors]).to be_empty
      end

      context 'when passing confidential as false' do
        let(:confidential) { false }

        it 'updates the issue confidentiality to false' do
          expect(mutated_issue.confidential).to be_falsey
        end
      end
    end
  end
end
