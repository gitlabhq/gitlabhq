require 'spec_helper'

describe Boards::Issues::ListService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :empty_repo, namespace: group) }
    let(:project1) { create(:project, :empty_repo, namespace: group) }
    let(:board)   { create(:board, group: group) }

    let(:m1) { create(:milestone, group: group) }
    let(:m2) { create(:milestone, group: group) }

    let(:bug) { create(:group_label, group: group, name: 'Bug') }
    let(:development) { create(:group_label, group: group, name: 'Development') }
    let(:testing)  { create(:group_label, group: group, name: 'Testing') }

    let(:p1) { create(:group_label, title: 'P1', group: group) }
    let(:p2) { create(:group_label, title: 'P2', group: group) }
    let(:p3) { create(:group_label, title: 'P3', group: group) }

    let(:user_list) { create(:user_list, board: board, position: 2) }
    let(:milestone_list) { create(:milestone_list, board: board, position: 3) }
    let(:backlog)   { create(:backlog_list, board: board) }
    let(:list1)     { create(:list, board: board, label: development, position: 0) }
    let(:list2)     { create(:list, board: board, label: testing, position: 1) }
    let(:closed)    { create(:closed_list, board: board) }

    let!(:opened_issue1) { create(:labeled_issue, project: project, milestone: m1, weight: 9, title: 'Issue 1', labels: [bug]) }
    let!(:opened_issue2) { create(:labeled_issue, project: project, milestone: m2, weight: 1, title: 'Issue 2', labels: [p2]) }
    let!(:opened_issue3) { create(:labeled_issue, project: project, milestone: m2, title: 'Assigned Issue', labels: [p3]) }
    let!(:reopened_issue1) { create(:issue, state: 'opened', project: project, title: 'Issue 3', closed_at: Time.now ) }

    let(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, development]) }
    let(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
    let(:list1_issue3) { create(:labeled_issue, project: project1, milestone: m1, labels: [development, p1]) }
    let(:list2_issue1) { create(:labeled_issue, project: project1, milestone: m1, labels: [testing]) }

    let(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
    let(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3]) }
    let(:closed_issue3) { create(:issue, :closed, project: project1) }
    let(:closed_issue4) { create(:labeled_issue, :closed, project: project1, labels: [p1]) }
    let(:closed_issue5) { create(:labeled_issue, :closed, project: project1, labels: [development]) }

    let(:parent) { group }

    before do
      stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)

      parent.add_developer(user)
      opened_issue3.assignees.push(user_list.user)
    end

    context 'milestone lists' do
      let!(:milestone_issue) { create(:labeled_issue, project: project, milestone: milestone_list.milestone, labels: [p3]) }

      it 'returns issues from milestone persisted in the list' do
        params = { board_id: board.id, id: milestone_list.id }

        issues = described_class.new(parent, user, params).execute

        expect(issues).to contain_exactly(milestone_issue)
      end

      context 'backlog list context' do
        it 'returns issues without milestones and without milestones from other lists' do
          params = { board_id: board.id, id: backlog.id }

          issues = described_class.new(parent, user, params).execute

          expect(issues).to contain_exactly(opened_issue1, # milestone from this issue is not in a list
                                            opened_issue2, # milestone from this issue is not in a list
                                            reopened_issue1) # has no milestone
        end
      end
    end

    context '#metadata' do
      it 'returns issues count and weight for list' do
        params = { board_id: board.id, id: backlog.id }

        metadata = described_class.new(parent, user, params).metadata

        expect(metadata[:size]).to eq(3)
        expect(metadata[:total_weight]).to eq(10)
      end

      # When collection is filtered by labels the ActiveRecord::Relation returns '{}' on #count or #sum
      # if no issues are found
      it 'returns 0 when filtering by labels and issues are not present' do
        params = { board_id: board.id, id: list1.id, label_name: [bug.title, p2.title] }

        metadata = described_class.new(parent, user, params).metadata

        expect(metadata[:size]).to eq(0)
        expect(metadata[:total_weight]).to eq(0)
      end
    end

    context 'when list_id is missing' do
      context 'when board is not scoped by milestone' do
        it 'returns opened issues without board labels and assignees applied' do
          params = { board_id: board.id }

          issues = described_class.new(parent, user, params).execute

          expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
        end
      end

      context 'when board is scoped by milestone' do
        it 'returns opened issues without board labels, assignees, or milestone applied' do
          params = { board_id: board.id }
          board.update_attribute(:milestone, m1)

          issues = described_class.new(parent, user, params).execute

          expect(issues)
            .to match_array([opened_issue2, list1_issue2, reopened_issue1, opened_issue1])
        end

        context 'when milestone is predefined' do
          let(:params) { { board_id: board.id, id: backlog.id } }

          context 'as upcoming' do
            before do
              board.update(milestone_id: Milestone::Upcoming.id)
            end

            it 'returns open issue for backlog without board label or assignees' do
              issues = described_class.new(parent, user, params).execute

              expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
            end
          end

          context 'as started' do
            before do
              board.update(milestone_id: Milestone::Started.id)
            end

            it 'returns open issue for backlog without board label or assignees' do
              issues = described_class.new(parent, user, params).execute

              expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
            end
          end
        end
      end
    end
  end
end
