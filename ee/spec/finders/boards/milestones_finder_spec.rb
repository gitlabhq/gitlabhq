require 'spec_helper'

describe Boards::MilestonesFinder do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: group) }

    let(:group_project) { create(:project, group: group) }
    let(:nested_group_project) { create(:project, group: nested_group) }

    let!(:group_milestone) { create(:milestone, group: group, project: nil) }
    let!(:group_project_milestone) { create(:milestone, project: group_project, group: nil) }
    let!(:nested_group_project_milestone) { create(:milestone, project: nested_group_project, group: nil) }
    let!(:nested_group_milestone) { create(:milestone, group: nested_group, project: nil) }
    let!(:deep_nested_group_milestone) { create(:milestone, group: deep_nested_group, project: nil) }

    let(:user) { create(:user) }
    let(:finder) { described_class.new(board, user) }

    context 'when project board', :nested_groups do
      let(:board) { create(:board, project: nested_group_project, group: nil) }

      it 'returns milestones from board project and ancestors groups' do
        group.add_developer(user)

        results = finder.execute

        expect(results).to contain_exactly(nested_group_project_milestone,
                                           nested_group_milestone,
                                           group_milestone)
      end
    end

    context 'when group board', :nested_groups do
      let(:board) { create(:board, project: nil, group: nested_group) }

      it 'returns milestones from board group and its ancestors' do
        group.add_developer(user)

        results = finder.execute

        expect(results).to contain_exactly(group_milestone,
                                           nested_group_milestone)
      end
    end
  end
end
