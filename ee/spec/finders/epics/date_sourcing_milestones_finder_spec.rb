# frozen_string_literal: true

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

      results = described_class.new(epic.id)

      expect(results).to have_attributes(
        start_date: milestone1.start_date,
        start_date_sourcing_milestone_id: milestone1.id,
        due_date: milestone2.due_date,
        due_date_sourcing_milestone_id: milestone2.id
      )
    end

    it 'returns date and id from single milestone' do
      epic = create(:epic)
      milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 10))
      create(:issue, epic: epic, milestone: milestone1)

      results = described_class.new(epic.id)

      expect(results).to have_attributes(
        start_date: milestone1.start_date,
        start_date_sourcing_milestone_id: milestone1.id,
        due_date: milestone1.due_date,
        due_date_sourcing_milestone_id: milestone1.id
      )
    end

    it 'returns date and id from milestone without date' do
      epic = create(:epic)
      milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1))
      create(:issue, epic: epic, milestone: milestone1)

      results = described_class.new(epic.id)

      expect(results).to have_attributes(
        start_date: milestone1.start_date,
        start_date_sourcing_milestone_id: milestone1.id,
        due_date: nil,
        due_date_sourcing_milestone_id: nil
      )
    end

    it 'handles epics without milestone' do
      epic = create(:epic)

      results = described_class.new(epic.id)

      expect(results).to have_attributes(
        start_date: nil,
        start_date_sourcing_milestone_id: nil,
        due_date: nil,
        due_date_sourcing_milestone_id: nil
      )
    end
  end
end
