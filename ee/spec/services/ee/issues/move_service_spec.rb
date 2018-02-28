require 'spec_helper'

describe Issues::MoveService do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project, group: create(:group)) }
  let(:old_issue) { create(:issue, project: old_project, author: user) }
  let(:move_service) { described_class.new(old_project, user) }

  describe '#rewrite_epic_issue' do
    context 'issue assigned to epic' do
      let!(:epic_issue) { create(:epic_issue, issue: old_issue) }

      before do
        stub_licensed_features(epics: true)
        old_project.add_reporter(user)
        new_project.add_reporter(user)
      end

      it 'updates epic issue reference' do
        epic_issue.epic.group.add_reporter(user)

        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.epic_issue).to eq(epic_issue)
      end

      it 'ignores epic issue reference if user can not update the epic' do
        new_issue = move_service.execute(old_issue, new_project)

        expect(new_issue.epic_issue).to be_nil
      end
    end
  end
end
