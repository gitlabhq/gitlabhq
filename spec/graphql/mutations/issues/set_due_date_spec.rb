# frozen_string_literal: true

require 'spec_helper'

describe Mutations::Issues::SetDueDate do
  let(:issue) { create(:issue) }
  let(:user) { create(:user) }
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:due_date) { 2.days.since }
    let(:mutated_issue) { subject[:issue] }
    subject { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, due_date: due_date) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the issue' do
      before do
        issue.project.add_developer(user)
      end

      it 'returns the issue with updated due date' do
        expect(mutated_issue).to eq(issue)
        expect(mutated_issue.due_date).to eq(Date.today + 2.days)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing incorrect due date value' do
        let(:due_date) { 'test' }

        it 'does not update due date' do
          expect(mutated_issue.due_date).to eq(issue.due_date)
        end
      end
    end
  end
end
