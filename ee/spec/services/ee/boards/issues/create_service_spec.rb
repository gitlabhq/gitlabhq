require 'spec_helper'

describe Boards::Issues::CreateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }

    subject(:service) do
      described_class.new(board.parent, project, user, board_id: board.id, list_id: list.id, title: 'New issue')
    end

    before do
      project.add_developer(user)
    end

    context 'assignees list' do
      before do
        stub_licensed_features(board_assignee_lists: true)
      end

      let(:list) do
        create(:list, board: board, user: user, list_type: List.list_types[:assignee], position: 0)
      end

      it 'assigns the issue to the List assignee' do
        issue = service.execute

        expect(issue.assignees).to eq([user])
      end
    end

    context 'milestone list' do
      before do
        stub_licensed_features(board_milestone_lists: true)
      end

      let(:milestone) { create(:milestone, project: project) }
      let(:list) do
        create(:list, board: board, milestone: milestone, list_type: List.list_types[:milestone], position: 0)
      end

      it 'assigns the issue to the list milestone' do
        issue = service.execute

        expect(issue.milestone).to eq(milestone)
      end
    end
  end
end
