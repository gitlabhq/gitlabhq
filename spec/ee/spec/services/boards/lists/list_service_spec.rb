require 'spec_helper'

describe Boards::Lists::ListService, services: true do
  let(:group) { create(:group) }
  let(:board) { create(:board, group: group) }
  let(:label) { create(:group_label, group: group) }
  let!(:list) { create(:list, board: board, label: label) }
  let(:service) { described_class.new(group, double) }

  describe '#execute' do
    context 'when the board has a backlog list' do
      let!(:backlog_list) { create(:backlog_list, board: board) }

      it 'does not create a backlog list' do
        expect { service.execute(board) }.not_to change(board.lists, :count)
      end

      it "returns board's lists" do
        expect(service.execute(board)).to eq [backlog_list, list, board.closed_list]
      end
    end

    context 'when the board does not have a backlog list' do
      it 'creates a backlog list' do
        expect { service.execute(board) }.to change(board.lists, :count).by(1)
      end

      it "returns board's lists" do
        expect(service.execute(board)).to eq [board.backlog_list, list, board.closed_list]
      end
    end
  end
end
