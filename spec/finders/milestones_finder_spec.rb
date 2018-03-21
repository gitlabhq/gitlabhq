require 'spec_helper'

describe MilestonesFinder do
  let(:group) { create(:group) }
  let(:project_1) { create(:project, namespace: group) }
  let(:project_2) { create(:project, namespace: group) }
  let!(:milestone_1) { create(:milestone, group: group, title: 'one test', due_date: Date.today) }
  let!(:milestone_2) { create(:milestone, group: group) }
  let!(:milestone_3) { create(:milestone, project: project_1, state: 'active', due_date: Date.tomorrow) }
  let!(:milestone_4) { create(:milestone, project: project_2, state: 'active') }

  it 'it returns milestones for projects' do
    result = described_class.new(project_ids: [project_1.id, project_2.id], state: 'all').execute

    expect(result).to contain_exactly(milestone_3, milestone_4)
  end

  it 'returns milestones for groups' do
    result = described_class.new(group_ids: group.id,  state: 'all').execute

    expect(result).to contain_exactly(milestone_1, milestone_2)
  end

  context 'milestones for groups and project' do
    let(:result) do
      described_class.new(project_ids: [project_1.id, project_2.id], group_ids: group.id, state: 'all').execute
    end

    it 'returns milestones for groups and projects' do
      expect(result).to contain_exactly(milestone_1, milestone_2, milestone_3, milestone_4)
    end

    it 'orders milestones by due date' do
      expect(result.first).to eq(milestone_1)
      expect(result.second).to eq(milestone_3)
    end
  end

  context 'with filters' do
    let(:params) do
      {
        project_ids: [project_1.id, project_2.id],
        group_ids: group.id,
        state: 'all'
      }
    end

    before do
      milestone_1.close
      milestone_3.close
    end

    it 'filters by active state' do
      params[:state] = 'active'
      result = described_class.new(params).execute

      expect(result).to contain_exactly(milestone_2, milestone_4)
    end

    it 'filters by closed state' do
      params[:state] = 'closed'
      result = described_class.new(params).execute

      expect(result).to contain_exactly(milestone_1, milestone_3)
    end

    it 'filters by title' do
      result = described_class.new(params.merge(title: 'one test')).execute

      expect(result.to_a).to contain_exactly(milestone_1)
    end
  end

  describe '#find_by' do
    it 'finds a single milestone' do
      finder = described_class.new(project_ids: [project_1.id], state: 'all')

      expect(finder.find_by(iid: milestone_3.iid)).to eq(milestone_3)
    end
  end
end
