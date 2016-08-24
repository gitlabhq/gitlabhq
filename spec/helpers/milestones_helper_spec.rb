require 'spec_helper'

describe MilestonesHelper do
  describe '#milestone_counts' do
    let(:project) { FactoryGirl.create(:project) }
    let(:counts) { helper.milestone_counts(project.milestones) }

    context 'when there are milestones' do
      let!(:milestone_1) { FactoryGirl.create(:active_milestone, project: project) }
      let!(:milestone_2) { FactoryGirl.create(:active_milestone, project: project) }
      let!(:milestone_3) { FactoryGirl.create(:closed_milestone, project: project) }

      it 'returns the correct counts' do
        expect(counts).to eq(opened: 2, closed: 1, all: 3)
      end
    end

    context 'when there are only milestones of one type' do
      let!(:milestone_1) { FactoryGirl.create(:active_milestone, project: project) }
      let!(:milestone_2) { FactoryGirl.create(:active_milestone, project: project) }

      it 'returns the correct counts' do
        expect(counts).to eq(opened: 2, closed: 0, all: 2)
      end
    end

    context 'when there are no milestones' do
      it 'returns the correct counts' do
        expect(counts).to eq(opened: 0, closed: 0, all: 0)
      end
    end
  end
end
