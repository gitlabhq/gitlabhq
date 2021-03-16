# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:dummy_gid) { 'gid://gitlab/Board/1' }

  shared_examples_for 'group and project boards resolver' do
    it 'does not create a default board' do
      expect(resolve_board(id: dummy_gid)).to eq nil
    end

    it 'calls Boards::BoardsFinder' do
      expect_next_instance_of(Boards::BoardsFinder) do |service|
        expect(service).to receive(:execute).and_return([])
      end

      resolve_board(id: dummy_gid)
    end

    it 'requires an ID' do
      expect do
        resolve(described_class, obj: board_parent, args: {}, ctx: { current_user: user })
      end.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end

    context 'when querying for a single board' do
      let(:board1) { create(:board, name: 'One', resource_parent: board_parent) }

      it 'returns specified board' do
        expect(resolve_board(id: global_id_of(board1))).to eq board1
      end

      it 'returns nil if board not found' do
        outside_parent = create(board_parent.class.underscore.to_sym) # rubocop:disable Rails/SaveBang
        outside_board  = create(:board, name: 'outside board', resource_parent: outside_parent)

        expect(resolve_board(id: global_id_of(outside_board))).to eq nil
      end
    end
  end

  describe '#resolve' do
    context 'when there is no parent' do
      let(:board_parent) { nil }

      it 'returns nil if parent is nil' do
        expect(resolve_board(id: dummy_gid)).to eq(nil)
      end
    end

    context 'when project boards' do
      let(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }

      it_behaves_like 'group and project boards resolver'
    end

    context 'when group boards' do
      let(:board_parent) { create(:group) }

      it_behaves_like 'group and project boards resolver'
    end
  end

  def resolve_board(id:)
    resolve(described_class, obj: board_parent, args: { id: id }, ctx: { current_user: user })
  end
end
