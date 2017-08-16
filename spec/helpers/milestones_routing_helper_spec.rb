require 'spec_helper'

describe MilestonesRoutingHelper do
  let(:project) { build_stubbed(:project) }
  let(:group) { build_stubbed(:group) }

  describe '#milestone_path' do
    context 'for a group milestone' do
      let(:milestone) { build_stubbed(:milestone, group: group, iid: 1) }

      it 'links to the group milestone page' do
        expect(milestone_path(milestone))
          .to eq(group_milestone_path(group, milestone))
      end
    end

    context 'for a project milestone' do
      let(:milestone) { build_stubbed(:milestone, project: project, iid: 1) }

      it 'links to the project milestone page' do
        expect(milestone_path(milestone))
          .to eq(project_milestone_path(project, milestone))
      end
    end
  end

  describe '#milestone_url' do
    context 'for a group milestone' do
      let(:milestone) { build_stubbed(:milestone, group: group, iid: 1) }

      it 'links to the group milestone page' do
        expect(milestone_url(milestone))
          .to eq(group_milestone_url(group, milestone))
      end
    end

    context 'for a project milestone' do
      let(:milestone) { build_stubbed(:milestone, project: project, iid: 1) }

      it 'links to the project milestone page' do
        expect(milestone_url(milestone))
          .to eq(project_milestone_url(project, milestone))
      end
    end
  end
end
