require 'spec_helper'

describe BoardsHelper do
  describe '#build_issue_link_base' do
    context 'project board' do
      it 'returns correct path for project board' do
        @project = create(:project)
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
    let(:project) { create(:project) }
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
end
