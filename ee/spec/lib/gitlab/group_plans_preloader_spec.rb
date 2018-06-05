# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GroupPlansPreloader do
  describe '#preload' do
    let!(:plan1) { create(:free_plan, name: 'plan-1') }
    let!(:plan2) { create(:free_plan, name: 'plan-2') }

    let(:preloaded_groups) do
      # We don't use the factory objects here because they might have the plan
      # loaded already (as we specify the plan when creating them).
      described_class.new.preload(Group.order(id: :asc))
    end

    before do
      group1 = create(:group, name: 'group-1', plan_id: plan1.id)

      create(:group, name: 'group-2', plan_id: plan2.id)
      create(:group, name: 'group-3', parent: group1)
    end

    it 'only executes three SQL queries to preload the data' do
      amount = ActiveRecord::QueryRecorder
        .new { preloaded_groups }
        .count

      # One query to get the groups and their ancestors, one query to get their
      # plans, and one query to _just_ get the groups.
      expect(amount).to eq(3)
    end

    it 'associates the correct plans with the correct groups' do
      expect(preloaded_groups[0].plans).to eq([plan1])
      expect(preloaded_groups[1].plans).to eq([plan2])
      expect(preloaded_groups[2].plans).to eq([plan1])
    end

    it 'does not execute any queries for preloaded plans' do
      preloaded_groups

      amount = ActiveRecord::QueryRecorder
        .new { preloaded_groups.each(&:plans) }
        .count

      expect(amount).to be_zero
    end
  end
end
