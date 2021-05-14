# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardsHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:base_group) { create(:group, path: 'base') }
  let_it_be(:project) { create(:project, group: base_group) }
  let_it_be(:project_board) { create(:board, project: project) }
  let_it_be(:group_board) { create(:board, group: base_group) }

  describe '#build_issue_link_base' do
    context 'project board' do
      it 'returns correct path for project board' do
        assign(:project, project)
        assign(:board, project_board)

        expect(helper.build_issue_link_base).to eq("/#{project.namespace.path}/#{project.path}/-/issues")
      end
    end

    context 'group board' do
      it 'returns correct path for base group' do
        assign(:board, group_board)

        expect(helper.build_issue_link_base).to eq('/base/:project_path/issues')
      end

      it 'returns correct path for subgroup' do
        subgroup = create(:group, parent: base_group, path: 'sub')
        assign(:board, create(:board, group: subgroup))

        expect(helper.build_issue_link_base).to eq('/base/sub/:project_path/issues')
      end
    end
  end

  describe '#board_base_url' do
    context 'when group board' do
      it 'generates the correct url' do
        assign(:board, group_board)
        assign(:group, base_group)

        expect(helper.board_base_url).to eq "http://test.host/groups/#{base_group.full_path}/-/boards"
      end
    end

    context 'when project board' do
      it 'generates the correct url' do
        assign(:board, project_board)
        assign(:project, project)

        expect(helper.board_base_url).to eq "/#{project.full_path}/-/boards"
      end
    end
  end

  describe '#current_board_namespace' do
    context 'when group board' do
      it 'returns the correct namespace' do
        assign(:board, group_board)
        assign(:group, base_group)

        expect(helper.current_board_namespace).to be(base_group)
      end
    end

    context 'project under group' do
      context 'when project board' do
        it 'returns the correct namespace' do
          assign(:project, project)
          assign(:board, project_board)

          expect(helper.current_board_namespace).to be(project.parent)
        end
      end
    end

    context 'project under user namespace' do
      let_it_be(:project_under_user) { create(:project, namespace: user.namespace) }

      context 'when project board' do
        let_it_be(:project_board) { create(:board, project: project_under_user) }

        it 'returns the correct namespace' do
          assign(:project, project_under_user)
          assign(:board, project_board)

          expect(helper.current_board_namespace).to be(user.namespace)
        end
      end
    end
  end

  describe '#board_data' do
    context 'project_board' do
      before do
        assign(:project, project)
        assign(:board, project_board)

        allow(helper).to receive(:current_user) { user }
        allow(helper).to receive(:can?).with(user, :create_non_backlog_issues, project_board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue, project_board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue_board_list, project).and_return(false)
      end

      it 'returns a board_lists_path as lists_endpoint' do
        expect(helper.board_data[:lists_endpoint]).to eq(board_lists_path(project_board))
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

      it 'returns the group id of a project' do
        expect(helper.board_data[:group_id]).to eq(project.group.id)
      end

      context 'can_admin_list' do
        it 'returns can_admin_list as false by default' do
          expect(helper.board_data[:can_admin_list]).to eq('false')
        end
        it 'returns can_admin_list as true when user can admin the board' do
          allow(helper).to receive(:can?).with(user, :admin_issue_board_list, project).and_return(true)

          expect(helper.board_data[:can_admin_list]).to eq('true')
        end
      end
    end

    context 'group board' do
      before do
        assign(:group, base_group)
        assign(:board, group_board)

        allow(helper).to receive(:current_user) { user }
        allow(helper).to receive(:can?).with(user, :create_non_backlog_issues, group_board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue, group_board).and_return(true)
        allow(helper).to receive(:can?).with(user, :admin_issue_board_list, base_group).and_return(false)
      end

      it 'returns correct path for base group' do
        expect(helper.build_issue_link_base).to eq("/#{base_group.full_path}/:project_path/issues")
      end

      it 'returns required label endpoints' do
        expect(helper.board_data[:labels_fetch_path]).to eq("/groups/#{base_group.full_path}/-/labels.json?include_ancestor_groups=true&only_group_labels=true")
        expect(helper.board_data[:labels_manage_path]).to eq("/groups/#{base_group.full_path}/-/labels")
      end

      it 'returns the group id' do
        expect(helper.board_data[:group_id]).to eq(base_group.id)
      end

      context 'can_admin_list' do
        it 'returns can_admin_list as false by default' do
          expect(helper.board_data[:can_admin_list]).to eq('false')
        end
        it 'returns can_admin_list as true when user can admin the board' do
          allow(helper).to receive(:can?).with(user, :admin_issue_board_list, base_group).and_return(true)

          expect(helper.board_data[:can_admin_list]).to eq('true')
        end
      end
    end
  end

  describe '#current_board_json' do
    let(:board_json) { helper.current_board_json }

    it 'can serialise with a basic set of attributes' do
      assign(:board, project_board)

      expect(board_json).to match_schema('current-board')
    end
  end
end
