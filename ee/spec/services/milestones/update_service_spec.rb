# frozen_string_literal: true
require 'spec_helper'

describe Milestones::UpdateService do
  let(:project) { create(:project) }
  let(:user) { build(:user) }
  let(:milestone) { create(:milestone, project: project) }

  describe '#execute' do
    context 'refresh related epic dates' do
      let(:epic) { create(:epic) }
      let!(:issue) { create(:issue, milestone: milestone, epic: epic) }
      let(:due_date) { 3.days.from_now.to_date }

      it 'calls epic#update_dates' do
        described_class.new(project, user, { due_date: due_date }).execute(milestone)

        epic.reload

        expect(epic.due_date).to eq(due_date)
      end
    end
  end
end
