require 'spec_helper'

describe EpicIssues::DestroyService do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, group: group) }
    let(:epic) { create(:epic, group: group) }
    let(:issue) { create(:issue, project: project) }
    let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

    subject { described_class.new(epic_issue, user).execute }

    context 'when user has permissions to remove associations' do
      before do
        group.add_reporter(user)
      end

      it 'removes related issue' do
        expect { subject }.to change { EpicIssue.count }.from(1).to(0)
      end

      it 'returns success message' do
        is_expected.to eq(message: 'Relation was removed', status: :success)
      end
    end

    context 'user does not have permissions to remove associations' do
      it 'does not remove relation' do
        expect { subject }.not_to change { EpicIssue.count }.from(1)
      end

      it 'returns error message' do
        is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
      end
    end
  end
end
