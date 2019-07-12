require 'spec_helper'

describe BoardsHelper do
  set(:project) { create(:project) }

  describe '#build_issue_link_base' do
    context 'project board' do
      it 'returns correct path for project board' do
        @project = project
        @board = create(:board, project: @project)

        expect(build_issue_link_base).to eq("/#{@project.namespace.path}/#{@project.path}/issues")
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
    let(:user) { create(:user) }
    let(:board) { create(:board, project: project) }

    before do
      assign(:board, board)
      assign(:project, project)

      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :admin_list, project).and_return(true)
    end

    it 'returns a board_lists_path as lists_endpoint' do
      expect(helper.board_data[:lists_endpoint]).to eq(board_lists_path(board))
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
