# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardsHelper do
  let_it_be(:project) { create(:project) }

  describe '#build_issue_link_base' do
    context 'project board' do
      it 'returns correct path for project board' do
        @project = project
        @board = create(:board, project: @project)

        expect(build_issue_link_base).to eq("/#{@project.namespace.path}/#{@project.path}/-/issues")
      end
    end

    context 'group board' do
      let(:base_group) { create(:group, path: 'base') }

      it 'returns correct path for base group' do
        @board = create(:board, group: base_group)

        expect(build_issue_link_base).to eq('/base/:project_path/issues')
      end

      it 'returns correct path for subgroup' do
        subgroup = create(:group, parent: base_group, path: 'sub')
        @board = create(:board, group: subgroup)

        expect(build_issue_link_base).to eq('/base/sub/:project_path/issues')
      end
    end
  end

  describe '#board_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:board) { create(:board, project: project) }

    context 'project_board' do
      before do
        assign(:project, project)
        assign(:board, board)

        allow(helper).to receive(:current_user) { user }
        allow(helper).to receive(:can?).with(user, :create_non_backlog_issues, board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue, board).and_return(true)
      end

      it 'returns a board_lists_path as lists_endpoint' do
        expect(helper.board_data[:lists_endpoint]).to eq(board_lists_path(board))
      end

      it 'returns board type as parent' do
        expect(helper.board_data[:parent]).to eq('project')
      end

      it 'returns can_update for user permissions on the board' do
        expect(helper.board_data[:can_update]).to eq('true')
      end

      it 'returns required label endpoints' do
        expect(helper.board_data[:labels_fetch_path]).to eq("/#{project.full_path}/-/labels.json?include_ancestor_groups=true")
        expect(helper.board_data[:labels_manage_path]).to eq("/#{project.full_path}/-/labels")
      end
    end

    context 'group board' do
      let_it_be(:group) { create(:group, path: 'base') }
      let_it_be(:board) { create(:board, group: group) }

      before do
        assign(:group, group)
        assign(:board, board)

        allow(helper).to receive(:current_user) { user }
        allow(helper).to receive(:can?).with(user, :create_non_backlog_issues, board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue, board).and_return(true)
      end

      it 'returns correct path for base group' do
        expect(helper.build_issue_link_base).to eq('/base/:project_path/issues')
      end

      it 'returns required label endpoints' do
        expect(helper.board_data[:labels_fetch_path]).to eq("/groups/base/-/labels.json?include_ancestor_groups=true&only_group_labels=true")
        expect(helper.board_data[:labels_manage_path]).to eq("/groups/base/-/labels")
      end
    end
  end

  describe '#current_board_json' do
    let(:board_json) { helper.current_board_json }

    it 'can serialise with a basic set of attributes' do
      board = create(:board, project: project)
      assign(:board, board)

      expect(board_json).to match_schema('current-board')
    end
  end
end
