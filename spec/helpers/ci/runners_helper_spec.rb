# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersHelper do
  let_it_be(:user, refind: true) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#runner_status_icon', :clean_gitlab_redis_cache do
    it "returns - not contacted yet" do
      runner = create(:ci_runner)
      expect(runner_status_icon(runner)).to include("not connected yet")
    end

    it "returns offline text" do
      runner = create(:ci_runner, contacted_at: 1.day.ago, active: true)
      expect(runner_status_icon(runner)).to include("Runner is offline")
    end

    it "returns online text" do
      runner = create(:ci_runner, contacted_at: 1.second.ago, active: true)
      expect(runner_status_icon(runner)).to include("Runner is online")
    end

    it "returns paused text" do
      runner = create(:ci_runner, contacted_at: 1.second.ago, active: false)
      expect(runner_status_icon(runner)).to include("Runner is paused")
    end
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

  describe '#toggle_shared_runners_settings_data' do
    let_it_be(:group) { create(:group) }

    let(:project_with_runners) { create(:project, namespace: group, shared_runners_enabled: true) }
    let(:project_without_runners) { create(:project, namespace: group, shared_runners_enabled: false) }

    context 'when project has runners' do
      it 'returns the correct value for is_enabled' do
        data = helper.toggle_shared_runners_settings_data(project_with_runners)
        expect(data[:is_enabled]).to eq("true")
      end
    end

    context 'when project does not have runners' do
      it 'returns the correct value for is_enabled' do
        data = helper.toggle_shared_runners_settings_data(project_without_runners)
        expect(data[:is_enabled]).to eq("false")
      end
    end

    context 'for all projects' do
      it 'returns the update path for toggling the shared runners setting' do
        data = helper.toggle_shared_runners_settings_data(project_with_runners)
        expect(data[:update_path]).to eq(toggle_shared_runners_project_runners_path(project_with_runners))
      end

      it 'returns false for is_disabled_and_unoverridable when project has no group' do
        project = create(:project)

        data = helper.toggle_shared_runners_settings_data(project)
        expect(data[:is_disabled_and_unoverridable]).to eq("false")
      end

      using RSpec::Parameterized::TableSyntax

      where(:shared_runners_setting, :is_disabled_and_unoverridable) do
        'enabled'                    | "false"
        'disabled_with_override'     | "false"
        'disabled_and_unoverridable' | "true"
      end

      with_them do
        it 'returns the override runner status for project with group' do
          group = create(:group)
          project = create(:project, group: group)
          allow(group).to receive(:shared_runners_setting).and_return(shared_runners_setting)

          data = helper.toggle_shared_runners_settings_data(project)
          expect(data[:is_disabled_and_unoverridable]).to eq(is_disabled_and_unoverridable)
        end
      end
    end
  end
end
