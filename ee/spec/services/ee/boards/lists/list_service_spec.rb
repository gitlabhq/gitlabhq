require 'spec_helper'

describe Boards::Lists::ListService do
  describe '#execute' do
    shared_examples 'list service for board with assignee lists' do
      let!(:assignee_list) { build(:user_list, board: board).tap { |l| l.save(validate: false) } }
      let!(:backlog_list) { create(:backlog_list, board: board) }
      let!(:list) { create(:list, board: board, label: label) }

      context 'when the feature is enabled' do
        before do
          allow(board.parent).to receive(:feature_available?).with(:board_assignee_lists).and_return(true)
          allow(board.parent).to receive(:feature_available?).with(:board_milestone_lists).and_return(false)
        end

        it 'returns all lists' do
          expect(service.execute(board)).to match_array [backlog_list, list, assignee_list, board.closed_list]
        end
      end

      context 'when the feature is disabled' do
        it 'filters out assignee lists that might have been created while subscribed' do
          expect(service.execute(board)).to match_array [backlog_list, list, board.closed_list]
        end
      end
    end

    shared_examples 'list service for board with milestone lists' do
      let!(:milestone_list) { build(:milestone_list, board: board).tap { |l| l.save(validate: false) } }
      let!(:backlog_list) { create(:backlog_list, board: board) }
      let!(:list) { create(:list, board: board, label: label) }

      context 'when the feature is enabled' do
        before do
          allow(board.parent).to receive(:feature_available?).with(:board_assignee_lists).and_return(false)
          allow(board.parent).to receive(:feature_available?).with(:board_milestone_lists).and_return(true)
        end

        it 'returns all lists' do
          expect(service.execute(board))
            .to match_array([backlog_list, list, milestone_list, board.closed_list])
        end
      end

      context 'when the feature is disabled' do
        it 'filters out assignee lists that might have been created while subscribed' do
          expect(service.execute(board)).to match_array [backlog_list, list, board.closed_list]
        end
      end
    end

    context 'when board parent is a project' do
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }
      let(:label) { create(:label, project: project) }
      let(:service) { described_class.new(project, double) }

      it_behaves_like 'list service for board with assignee lists'
      it_behaves_like 'list service for board with milestone lists'
    end

    context 'when board parent is a group' do
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:label) { create(:group_label, group: group) }
      let(:service) { described_class.new(group, double) }

      it_behaves_like 'list service for board with assignee lists'
      it_behaves_like 'list service for board with milestone lists'
    end
  end
end
