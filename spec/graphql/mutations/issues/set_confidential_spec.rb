# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetConfidential do
  let(:project) { create(:project, :private) }
  let(:issue) { create(:issue, project: project, assignees: [user]) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue) }

  describe '#resolve' do
    let(:confidential) { true }
    let(:mutated_issue) { subject[:issue] }

    subject { mutation.resolve(project_path: project.full_path, iid: issue.iid, confidential: confidential) }

    before do
      stub_spam_services
    end

    it_behaves_like 'permission level for issue mutation is correctly verified'

    context 'when the user can update the issue' do
      before do
        project.add_developer(user)
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

    context 'when guest user is an assignee' do
      let(:project) { create(:project, :public) }

      before do
        project.add_guest(user)
      end

      it 'does not change issue confidentiality' do
        expect(mutated_issue).to eq(issue)
        expect(mutated_issue.confidential).to be_falsey
        expect(subject[:errors]).to be_empty
      end
    end
  end
end
