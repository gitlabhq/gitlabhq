require 'spec_helper'

describe Epics::DateSourcingMilestonesFinder do
  describe '#execute' do
    it 'returns date and id from milestones' do
      epic = create(:epic)
      milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 10))
      milestone2 = create(:milestone, due_date: Date.new(2000, 1, 30))
      milestone3 = create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 20))
      create(:issue, epic: epic, milestone: milestone1)
      create(:issue, epic: epic, milestone: milestone2)
      create(:issue, epic: epic, milestone: milestone3)

      results = described_class.execute(epic.id)

      expect(results.start_date).to eq(milestone1.start_date)
      expect(results.start_date_sourcing_milestone_id).to eq(milestone1.id)
      expect(results.due_date).to eq(milestone2.due_date)
      expect(results.due_date_sourcing_milestone_id).to eq(milestone2.id)
    end

    it 'returns date and id from single milestone' do
      epic = create(:epic)
      milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 10))
      create(:issue, epic: epic, milestone: milestone1)

      results = described_class.execute(epic.id)

      expect(results.start_date).to eq(milestone1.start_date)
      expect(results.start_date_sourcing_milestone_id).to eq(milestone1.id)
      expect(results.due_date).to eq(milestone1.due_date)
      expect(results.due_date_sourcing_milestone_id).to eq(milestone1.id)
    end

    it 'returns date and id from milestone without date' do
      epic = create(:epic)
      milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1))
      create(:issue, epic: epic, milestone: milestone1)

      results = described_class.execute(epic.id)

      expect(results.start_date).to eq(milestone1.start_date)
      expect(results.start_date_sourcing_milestone_id).to eq(milestone1.id)
      expect(results.due_date).to eq(nil)
      expect(results.due_date_sourcing_milestone_id).to eq(nil)
    end

    it 'handles epics without milestone' do
      epic = create(:epic)

      results = described_class.execute(epic.id)

      expect(results.start_date).to eq(nil)
      expect(results.start_date_sourcing_milestone_id).to eq(nil)
      expect(results.due_date).to eq(nil)
      expect(results.due_date_sourcing_milestone_id).to eq(nil)
    end
  end
end
