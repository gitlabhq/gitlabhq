# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  shared_examples_for 'group and project boards resolver' do
    it 'does not create a default board' do
      expect(resolve_boards).to be_empty
    end

    it 'calls Boards::BoardsFinder' do
      expect_next_instance_of(Boards::BoardsFinder) do |service|
        expect(service).to receive(:execute)
      end

      resolve_boards
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { resolve_boards(args: {}) }

      create(:milestone, "#{board_parent.class.name.underscore}": board_parent)
      create(:board, resource_parent: board_parent)

      expect { resolve_boards(args: {}) }.not_to exceed_query_limit(control)
    end

    describe 'multiple_issue_boards_available?' do
      let!(:board2) { create(:board, name: 'Two', resource_parent: board_parent) }
      let!(:board1) { create(:board, name: 'One', resource_parent: board_parent) }

      it 'returns multiple boards' do
        allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(true)

        expect(resolve_boards).to eq [board1, board2]
      end

      it 'returns only the first boards' do
        allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)

        expect(resolve_boards).to eq [board1]
      end
    end

    context 'when querying for a single board' do
      let(:board1) { create(:board, name: 'One', resource_parent: board_parent) }

      it 'returns specified board' do
        expect(resolve_boards(args: { id: global_id_of(board1) })).to eq [board1]
      end

      it 'returns nil if board not found' do
        outside_parent = create(board_parent.class.underscore.to_sym) # rubocop:disable Rails/SaveBang
        outside_board  = create(:board, name: 'outside board', resource_parent: outside_parent)

        expect(resolve_boards(args: { id: global_id_of(outside_board) })).to eq Board.none
      end
    end
  end

  describe '#resolve' do
    context 'when there is no parent' do
      let(:board_parent) { nil }

      it 'returns none if parent is nil' do
        expect(resolve_boards).to eq(Board.none)
      end
    end

    context 'when project boards' do
      let(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace) }

      it_behaves_like 'group and project boards resolver'
    end

    context 'when group boards' do
      let(:board_parent) { create(:group) }

      it_behaves_like 'group and project boards resolver'
    end
  end

  def resolve_boards(args: {})
    resolve(described_class, obj: board_parent, args: args, ctx: { current_user: user })
  end
end
