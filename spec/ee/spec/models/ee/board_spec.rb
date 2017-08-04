require 'spec_helper'

describe Board do
  describe 'milestone' do
    subject(:board) { build(:board) }

    context 'when the feature is available' do
      before do
        stub_licensed_features(issue_board_milestone: true)
      end

      it 'returns Milestone::Upcoming for upcoming milestone id' do
        board.milestone_id = Milestone::Upcoming.id

        expect(board.milestone).to eq Milestone::Upcoming
      end

      it 'returns milestone for valid milestone id' do
        milestone = create(:milestone)
        board.milestone_id = milestone.id

        expect(board.milestone).to eq milestone
      end

      it 'returns nil for invalid milestone id' do
        board.milestone_id = -1

        expect(board.milestone).to be_nil
      end
    end

    it 'returns nil when the feature is not available' do
      stub_licensed_features(issue_board_milestone: false)
      milestone = create(:milestone)
      board.milestone_id = milestone.id

      expect(board.milestone).to be_nil
    end
  end
end
