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

    let!(:backlog) { create(:backlog_list, board: board) }
    let!(:list1)   { create(:list, board: board, label: development, position: 0) }
    let!(:list2)   { create(:list, board: board, label: testing, position: 1) }
    let!(:closed)  { create(:closed_list, board: board) }

    let!(:opened_issue1) { create(:labeled_issue, project: project, milestone: m1, title: 'Issue 1', labels: [bug]) }
    let!(:opened_issue2) { create(:labeled_issue, project: project, milestone: m2, title: 'Issue 2', labels: [p2]) }
    let!(:reopened_issue1) { create(:issue, state: 'opened', project: project, title: 'Issue 3', closed_at: Time.now ) }

    let!(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, development]) }
    let!(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
    let!(:list1_issue3) { create(:labeled_issue, project: project1, milestone: m1, labels: [development, p1]) }
    let!(:list2_issue1) { create(:labeled_issue, project: project1, milestone: m1, labels: [testing]) }

    let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
    let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3]) }
    let!(:closed_issue3) { create(:issue, :closed, project: project1) }
    let!(:closed_issue4) { create(:labeled_issue, :closed, project: project1, labels: [p1]) }
    let!(:closed_issue5) { create(:labeled_issue, :closed, project: project1, labels: [development]) }

    let(:parent) { group }

    before do
      parent.add_developer(user)
    end

    context 'when list_id is missing' do
      context 'when board does not have a milestone' do
        it 'returns opened issues without board labels applied' do
          params = { board_id: board.id }

          issues = described_class.new(parent, user, params).execute

          expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
        end
      end

      context 'when board have a milestone' do
        it 'returns opened issues without board labels and milestone applied' do
          params = { board_id: board.id }
          board.update_attribute(:milestone, m1)

          issues = described_class.new(parent, user, params).execute

          expect(issues).to match_array([opened_issue2, list1_issue2, reopened_issue1, opened_issue1])
        end

        context 'when milestone is predefined' do
          let(:params) { { board_id: board.id, id: backlog.id } }

          context 'as upcoming' do
            before do
              board.update(milestone_id: Milestone::Upcoming.id)
            end

            it 'returns open issue for backlog without board label' do
              issues = described_class.new(parent, user, params).execute

              expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
            end
          end

          context 'as started' do
            before do
              board.update(milestone_id: Milestone::Started.id)
            end

            it 'returns open issue for backlog without board label' do
              issues = described_class.new(parent, user, params).execute

              expect(issues).to match_array([opened_issue2, reopened_issue1, opened_issue1])
            end
          end
        end
      end
    end
  end
end
