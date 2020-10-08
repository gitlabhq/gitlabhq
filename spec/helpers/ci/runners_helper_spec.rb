# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersHelper do
  it "returns - not contacted yet" do
    runner = FactoryBot.build :ci_runner
    expect(runner_status_icon(runner)).to include("not connected yet")
  end

  it "returns offline text" do
    runner = FactoryBot.build(:ci_runner, contacted_at: 1.day.ago, active: true)
    expect(runner_status_icon(runner)).to include("Runner is offline")
  end

  it "returns online text" do
    runner = FactoryBot.build(:ci_runner, contacted_at: 1.second.ago, active: true)
    expect(runner_status_icon(runner)).to include("Runner is online")
  end

  describe '#runner_contacted_at' do
    let(:contacted_at_stored) { 1.hour.ago.change(usec: 0) }
    let(:contacted_at_cached) { 1.second.ago.change(usec: 0) }
    let(:runner) { create(:ci_runner, contacted_at: contacted_at_stored) }

    before do
      runner.cache_attributes(contacted_at: contacted_at_cached)
    end

    context 'without sorting' do
      it 'returns cached value' do
        expect(runner_contacted_at(runner)).to eq(contacted_at_cached)
      end
    end

    context 'with sorting set to created_date' do
      before do
        controller.params[:sort] = 'created_date'
      end

      it 'returns cached value' do
        expect(runner_contacted_at(runner)).to eq(contacted_at_cached)
      end
    end

    context 'with sorting set to contacted_asc' do
      before do
        controller.params[:sort] = 'contacted_asc'
      end

      it 'returns stored value' do
        expect(runner_contacted_at(runner)).to eq(contacted_at_stored)
      end
    end
  end

  describe '#group_shared_runners_settings_data' do
    let(:group) { create(:group, parent: parent, shared_runners_enabled: false) }
    let(:parent) { create(:group) }

    it 'returns group data for top level group' do
      data = group_shared_runners_settings_data(parent)

      expect(data[:update_path]).to eq("/api/v4/groups/#{parent.id}")
      expect(data[:shared_runners_availability]).to eq('enabled')
      expect(data[:parent_shared_runners_availability]).to eq(nil)
    end

    it 'returns group data for child group' do
      data = group_shared_runners_settings_data(group)

      expect(data[:update_path]).to eq("/api/v4/groups/#{group.id}")
      expect(data[:shared_runners_availability]).to eq('disabled_and_unoverridable')
      expect(data[:parent_shared_runners_availability]).to eq('enabled')
    end
  end
end
