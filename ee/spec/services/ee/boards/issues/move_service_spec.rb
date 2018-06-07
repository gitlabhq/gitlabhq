require 'spec_helper'

describe Boards::Issues::MoveService, services: true do
  shared_examples 'moving an issue to/from assignee lists' do
    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development]) }
    let(:params) { { board_id: board1.id, from_list_id: list1.id, to_list_id: list2.id } }

    context 'from assignee to label list' do
      it 'does not unassign and adds label' do
        params = { board_id: board1.id, from_list_id: list3.id, to_list_id: list2.id }
        issue.assignees.push(list3.user)
        expect(issue.assignees).to contain_exactly(list3.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development, testing)
        expect(issue.assignees).to contain_exactly(list3.user)
      end
    end

    context 'from assignee to backlog' do
      it 'removes assignment' do
        params = { board_id: board1.id, from_list_id: list3.id, to_list_id: backlog.id }
        issue.assignees.push(list3.user)
        expect(issue.assignees).to contain_exactly(list3.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to eq([])
        expect(issue).not_to be_closed
      end
    end

    context 'from assignee to closed list' do
      it 'keeps assignment and closes the issue' do
        params = { board_id: board1.id, from_list_id: list3.id, to_list_id: closed.id }
        issue.assignees.push(list3.user)
        expect(issue.assignees).to contain_exactly(list3.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to contain_exactly(list3.user)
        expect(issue).to be_closed
      end
    end

    context 'from label list to assignee' do
      it 'assigns and does not remove label' do
        params = { board_id: board1.id, from_list_id: list1.id, to_list_id: list3.id }

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development)
        expect(issue.assignees).to contain_exactly(list3.user)
      end
    end

    context 'between two assignee lists' do
      it 'unassigns removal and assigns addition' do
        params = { board_id: board1.id, from_list_id: list3.id, to_list_id: list4.id }
        issue.assignees.push(list3.user)
        expect(issue.assignees).to contain_exactly(list3.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development)
        expect(issue.assignees).to contain_exactly(user)
      end
    end
  end

  describe '#execute' do
    let(:user) { create(:user) }

    let!(:board1) { create(:board, **parent_attr) }
    let(:board2) { create(:board, **parent_attr) }

    let(:list1)   { create(:list, board: board1, label: development, position: 0) }
    let(:list2)   { create(:list, board: board1, label: testing, position: 1) }
    let(:list3)   { create(:user_list, board: board1, position: 2) }
    let(:list4)   { create(:user_list, board: board1, user: user, position: 3) }
    let(:closed)  { create(:closed_list, board: board1) }
    let(:backlog) { create(:backlog_list, board: board1) }

    context 'when parent is a project' do
      let(:project) { create(:project) }
      let(:parent_attr) { { project: project } }
      let(:parent) { project }

      let(:bug) { create(:label, project: project, name: 'Bug') }
      let(:development) { create(:label, project: project, name: 'Development') }
      let(:testing)  { create(:label, project: project, name: 'Testing') }
      let(:regression) { create(:label, project: project, name: 'Regression') }

      before do
        stub_licensed_features(board_assignee_lists: true)
        parent.add_developer(user)
        parent.add_developer(list3.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
    end

    context 'when parent is a group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:parent_attr) { { group: group } }
      let(:parent) { group }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing)  { create(:group_label, group: group, name: 'Testing') }
      let(:regression) { create(:group_label, group: group, name: 'Regression') }

      before do
        stub_licensed_features(board_assignee_lists: true)
        parent.add_developer(user)
        parent.add_developer(list3.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
    end
  end
end
