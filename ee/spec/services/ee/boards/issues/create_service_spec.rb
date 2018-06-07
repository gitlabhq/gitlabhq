require 'spec_helper'

describe Boards::Issues::CreateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }
    let(:list)    { create(:list, board: board, user: user, list_type: List.list_types[:assignee], position: 0) }

    subject(:service) { described_class.new(board.parent, project, user, board_id: board.id, list_id: list.id, title: 'New issue') }

    before do
      stub_licensed_features(board_assignee_lists: true)
      project.add_developer(user)
    end

    it 'assigns the issue to the List assignee' do
      issue = service.execute

      expect(issue.assignees).to eq([user])
    end
  end
end
