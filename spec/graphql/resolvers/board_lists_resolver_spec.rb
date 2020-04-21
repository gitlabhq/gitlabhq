# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::BoardListsResolver do
  include GraphqlHelpers

  let_it_be(:user)          { create(:user) }
  let_it_be(:guest)         { create(:user) }
  let_it_be(:unauth_user)   { create(:user) }
  let_it_be(:project)       { create(:project, creator_id: user.id, namespace: user.namespace ) }
  let_it_be(:group)         { create(:group, :private) }
  let_it_be(:project_label) { create(:label, project: project, name: 'Development') }
  let_it_be(:group_label)   { create(:group_label, group: group, name: 'Development') }

  shared_examples_for 'group and project board lists resolver' do
    let(:board) { create(:board, resource_parent: board_parent) }

    before do
      board_parent.add_developer(user)
    end

    it 'does not create the backlog list' do
      lists = resolve_board_lists.items

      expect(lists.count).to eq 1
      expect(lists[0].list_type).to eq 'closed'
    end

    context 'with unauthorized user' do
      it 'raises an error' do
        expect do
          resolve_board_lists(current_user: unauth_user)
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when authorized' do
      let!(:label_list) { create(:list, board: board, label: label) }
      let!(:backlog_list) { create(:backlog_list, board: board) }

      it 'returns a list of board lists' do
        lists = resolve_board_lists.items

        expect(lists.count).to eq 3
        expect(lists.map(&:list_type)).to eq %w(backlog label closed)
      end

      context 'when another user has list preferences' do
        before do
          board.lists.first.update_preferences_for(guest, collapsed: true)
        end

        it 'returns the complete list of board lists for this user' do
          lists = resolve_board_lists.items

          expect(lists.count).to eq 3
        end
      end
    end
  end

  describe '#resolve' do
    context 'when project boards' do
      let(:board_parent) { project }
      let(:label) { project_label }

      it_behaves_like 'group and project board lists resolver'
    end

    context 'when group boards' do
      let(:board_parent) { group }
      let(:label) { group_label }

      it_behaves_like 'group and project board lists resolver'
    end
  end

  def resolve_board_lists(args: {}, current_user: user)
    resolve(described_class, obj: board, args: args, ctx: { current_user: current_user })
  end
end
