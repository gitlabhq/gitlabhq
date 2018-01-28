require 'spec_helper'

describe BoardsHelper do
  describe '#board_data' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:board) { create(:board, project: project) }

    before do
      assign(:board, board)
      assign(:project, project)

      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :admin_list, project).and_return(true)
    end

    it 'returns a board_lists_path as lists_endpoint' do
      expect(helper.board_data[:lists_endpoint]).to eq(board_lists_path(board))
    end
  end
end
