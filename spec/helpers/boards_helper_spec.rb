require 'spec_helper'

describe BoardsHelper do
  describe '#build_issue_link_base' do
    it 'returns correct path for project board' do
      @project = create(:project)
      @board = create(:board, project: @project)

      expect(build_issue_link_base).to eq("/#{@project.namespace.path}/#{@project.path}/issues")
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
end
