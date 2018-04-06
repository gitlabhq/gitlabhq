require 'spec_helper'

describe Boards::ListService do
  shared_examples 'boards list service' do
    let(:service) { described_class.new(parent, double) }
    let!(:boards) { create_list(:board, 3, parent: parent) }

    describe '#execute' do
      it 'returns all issue boards when multiple issue boards is enabled' do
        if parent.is_a?(Group)
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        expect(service.execute.size).to eq(3)
      end

      it 'returns the first issue board when multiple issue boards is disabled' do
        if parent.is_a?(Project)
          stub_licensed_features(multiple_project_issue_boards: false)
        end

        expect(service.execute.size).to eq(1)
      end

      it 'returns boards ordered by name' do
        board_names = ['a-board', 'B-board', 'c-board'].shuffle
        boards.each_with_index { |board, i| board.update_column(:name, board_names[i]) }
        stub_licensed_features(multiple_group_issue_boards: true)

        expect(service.execute.pluck(:name)).to eq(['a-board', 'B-board', 'c-board'])
      end
    end
  end

  it_behaves_like 'boards list service' do
    let(:parent) { create(:project, :empty_repo) }
  end

  it_behaves_like 'boards list service' do
    let(:parent) { create(:group) }
  end
end
