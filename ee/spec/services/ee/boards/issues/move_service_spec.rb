require 'spec_helper'

describe Boards::Issues::MoveService, services: true do
  shared_examples 'moving an issue to/from milestone lists' do
    context 'from backlog to milestone list' do
      let!(:issue) { create(:labeled_issue, project: project) }

      it 'assigns the milestone' do
        params = { board_id: board1.id, from_list_id: backlog.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)
      end
    end

    context 'from milestone to backlog list' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'removes the milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: backlog.id }
        expect { described_class.new(parent, user, params).execute(issue) } .to change { issue.reload.milestone }
          .from(milestone_list1.milestone)
          .to(nil)
      end
    end

    context 'from label to milestone list' do
      let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development]) }

      it 'assigns the milestone and keeps labels' do
        params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)

        expect(issue.labels).to contain_exactly(bug, development)
      end
    end

    context 'from milestone to label list' do
      let!(:issue) do
        create(:labeled_issue, project: project,
                               milestone: milestone_list1.milestone,
                               labels: [bug, development])
      end

      it 'adds labels and keeps milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: label_list2.id }

        described_class.new(parent, user, params).execute(issue)
        issue.reload

        expect(issue.labels).to contain_exactly(bug, development, testing)
      end
    end

    context 'from assignee to milestone list' do
      let!(:issue) { create(:labeled_issue, project: project, assignees: [user], milestone: nil) }

      it 'assigns the milestone and keeps assignees' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)

        expect(issue.assignees).to eq([user])
      end
    end

    context 'from milestone to assignee list' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'assigns the user and keeps milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: user_list1.id }

        described_class.new(parent, user, params).execute(issue)
        issue.reload

        expect(issue.milestone).to eq(milestone_list1.milestone)
        expect(issue.assignees).to contain_exactly(user_list1.user)
      end
    end

    context 'between milestone lists' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'replaces previous list milestone to targeting list milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: milestone_list2.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(milestone_list1.milestone)
          .to(milestone_list2.milestone)
      end
    end
  end

  shared_examples 'moving an issue to/from assignee lists' do
    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development]) }
    let(:params) { { board_id: board1.id, from_list_id: label_list1.id, to_list_id: label_list2.id } }

    context 'from assignee to label list' do
      it 'does not unassign and adds label' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: label_list2.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development, testing)
        expect(issue.assignees).to contain_exactly(user_list1.user)
      end
    end

    context 'from assignee to backlog' do
      it 'removes assignment' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: backlog.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to eq([])
        expect(issue).not_to be_closed
      end
    end

    context 'from assignee to closed list' do
      it 'keeps assignment and closes the issue' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: closed.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to contain_exactly(user_list1.user)
        expect(issue).to be_closed
      end
    end

    context 'from label list to assignee' do
      it 'assigns and does not remove label' do
        params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: user_list1.id }

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development)
        expect(issue.assignees).to contain_exactly(user_list1.user)
      end
    end

    context 'between two assignee lists' do
      it 'unassigns removal and assigns addition' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: user_list2.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

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

    let(:label_list1) { create(:list, board: board1, label: development, position: 0) }
    let(:label_list2) { create(:list, board: board1, label: testing, position: 1) }
    let(:user_list1) { create(:user_list, board: board1, position: 2) }
    let(:user_list2) { create(:user_list, board: board1, user: user, position: 3) }
    let(:milestone_list1) { create(:milestone_list, board: board1, milestone: milestone1, position: 4) }
    let(:milestone_list2) { create(:milestone_list, board: board1, milestone: milestone2, position: 5) }
    let(:closed) { create(:closed_list, board: board1) }
    let(:backlog) { create(:backlog_list, board: board1) }

    context 'when parent is a project' do
      let(:project) { create(:project) }
      let(:parent_attr) { { project: project } }
      let(:parent) { project }
      let(:milestone1) { create(:milestone, project: project) }
      let(:milestone2) { create(:milestone, project: project) }

      let(:bug) { create(:label, project: project, name: 'Bug') }
      let(:development) { create(:label, project: project, name: 'Development') }
      let(:testing)  { create(:label, project: project, name: 'Testing') }
      let(:regression) { create(:label, project: project, name: 'Regression') }

      before do
        stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
        parent.add_developer(user)
        parent.add_developer(user_list1.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
      it_behaves_like 'moving an issue to/from milestone lists'
    end

    context 'when parent is a group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:parent_attr) { { group: group } }
      let(:parent) { group }
      let(:milestone1) { create(:milestone, group: group) }
      let(:milestone2) { create(:milestone, group: group) }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing)  { create(:group_label, group: group, name: 'Testing') }
      let(:regression) { create(:group_label, group: group, name: 'Regression') }

      before do
        stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
        parent.add_developer(user)
        parent.add_developer(user_list1.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
      it_behaves_like 'moving an issue to/from milestone lists'
    end
  end
end
