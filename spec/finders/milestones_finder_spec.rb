require 'spec_helper'

describe MilestonesFinder do
  let(:group) { create(:group) }
  let(:project_1) { create(:empty_project, namespace: group) }
  let(:project_2) { create(:empty_project, namespace: group) }
  let!(:milestone_1) { create(:milestone, group: group) }
  let!(:milestone_2) { create(:milestone, group: group) }
  let!(:milestone_3) { create(:milestone, project: project_1, state: 'active') }
  let!(:milestone_4) { create(:milestone, project: project_2, state: 'active') }

  it 'it returns milestones for projects' do
    result = described_class.new(projects: [project_1, project_2], params: { state: 'all' }).execute

    expect(result).to contain_exactly(milestone_3, milestone_4)
  end

  it 'returns milestones for groups' do
    result = described_class.new(groups: group, params: { state: 'all' }).execute

    expect(result).to contain_exactly(milestone_1, milestone_2)
  end

  it 'returns milestones for groups and projects' do
    result = described_class.new(projects: [project_1, project_2], groups: group, params: { state: 'all' }).execute

    expect(result).to contain_exactly(milestone_1, milestone_2, milestone_3, milestone_4)
  end

  context 'state filtering' do
    before do
      milestone_1.close
      milestone_3.close
    end

    it 'filters by active state' do
      result = described_class.new(projects: [project_1, project_2], groups: group, params: { state: 'active' }).execute

      expect(result).to contain_exactly(milestone_2, milestone_4)
    end

    it 'filters by closed state' do
      result = described_class.new(projects: [project_1, project_2], groups: group, params: { state: 'closed' }).execute

      expect(result).to contain_exactly(milestone_1, milestone_3)
    end
  end
end
