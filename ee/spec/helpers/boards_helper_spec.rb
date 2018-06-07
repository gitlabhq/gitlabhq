
require 'spec_helper'

describe BoardsHelper do
  describe '#board_list_data' do
    let(:results) { helper.board_list_data }

    it 'contains an endpoint to get users list' do
      project = create(:project)
      board = create(:board, project: project)
      assign(:board, board)
      assign(:project, project)

      expect(results).to include(list_assignees_path: "/-/boards/#{board.id}/users.json")
    end
  end
end
