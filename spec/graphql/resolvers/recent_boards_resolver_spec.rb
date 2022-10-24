# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RecentBoardsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  shared_examples_for 'group and project recent boards resolver' do
    let_it_be(:board1) { create(:board, name: 'One', resource_parent: board_parent) }
    let_it_be(:board2) { create(:board, name: 'Two', resource_parent: board_parent) }

    before do
      [board1, board2].each { |board| visit_board(board, board_parent) }
    end

    it 'calls ::Boards::VisitsFinder' do
      expect_any_instance_of(::Boards::VisitsFinder) do |finder|
        expect(finder).to receive(:latest)
      end

      resolve_recent_boards
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { resolve_recent_boards }

      board3 = create(:board, resource_parent: board_parent)
      visit_board(board3, board_parent)

      expect { resolve_recent_boards(args: {}) }.not_to exceed_query_limit(control)
    end

    it 'returns most recent visited boards' do
      expect(resolve_recent_boards).to match_array [board2, board1]
    end

    it 'returns a set number of boards' do
      stub_const('Board::RECENT_BOARDS_SIZE', 1)

      expect(resolve_recent_boards).to match_array [board2]
    end
  end

  describe '#resolve' do
    context 'when there is no parent' do
      let_it_be(:board_parent) { nil }

      it 'returns none if parent is nil' do
        expect(resolve_recent_boards).to eq(Board.none)
      end
    end

    context 'when project boards' do
      let_it_be(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace) }

      it_behaves_like 'group and project recent boards resolver'
    end

    context 'when group boards' do
      let_it_be(:board_parent) { create(:group) }

      it_behaves_like 'group and project recent boards resolver'
    end
  end

  def resolve_recent_boards(args: {})
    resolve(described_class, obj: board_parent, args: args, ctx: { current_user: user })
  end

  def visit_board(board, parent)
    if parent.is_a?(Group)
      create(:board_group_recent_visit, group: parent, board: board, user: user)
    else
      create(:board_project_recent_visit, project: parent, board: board, user: user)
    end
  end
end
