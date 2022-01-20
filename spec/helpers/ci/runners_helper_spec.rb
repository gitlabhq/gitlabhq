# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersHelper do
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#runner_status_icon', :clean_gitlab_redis_cache do
    it "returns - not contacted yet" do
      runner = create(:ci_runner)
      expect(helper.runner_status_icon(runner)).to include("not contacted yet")
    end

    it "returns offline text" do
      runner = create(:ci_runner, contacted_at: 1.day.ago, active: true)
      expect(helper.runner_status_icon(runner)).to include("Runner is offline")
    end

    it "returns online text" do
      runner = create(:ci_runner, contacted_at: 1.second.ago, active: true)
      expect(helper.runner_status_icon(runner)).to include("Runner is online")
    end

    it "returns paused text" do
      runner = create(:ci_runner, contacted_at: 1.second.ago, active: false)
      expect(helper.runner_status_icon(runner)).to include("Runner is paused")
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
        expect(helper.runner_contacted_at(runner)).to eq(contacted_at_cached)
      end
    end

    context 'with sorting set to created_date' do
      before do
        controller.params[:sort] = 'created_date'
      end

      it 'returns cached value' do
        expect(helper.runner_contacted_at(runner)).to eq(contacted_at_cached)
      end
    end

    context 'with sorting set to contacted_asc' do
      before do
        controller.params[:sort] = 'contacted_asc'
      end

      it 'returns stored value' do
        expect(helper.runner_contacted_at(runner)).to eq(contacted_at_stored)
      end
    end
  end

  describe '#admin_runners_data_attributes' do
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:project_runner) { create(:ci_runner, :project ) }

    before do
      allow(helper).to receive(:current_user).and_return(admin)
    end

    it 'returns the data in format' do
      expect(helper.admin_runners_data_attributes).to eq({
        runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
        registration_token: Gitlab::CurrentSettings.runners_registration_token
      })
    end
  end

  describe '#group_shared_runners_settings_data' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent, shared_runners_enabled: false) }

    let(:runner_constants) do
      {
        runner_enabled: Namespace::SR_ENABLED,
        runner_disabled: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,
        runner_allow_override: Namespace::SR_DISABLED_WITH_OVERRIDE
      }
    end

    it 'returns group data for top level group' do
      result = {
        update_path: "/api/v4/groups/#{parent.id}",
        shared_runners_availability: Namespace::SR_ENABLED,
        parent_shared_runners_availability: nil
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(parent)).to eq result
    end

    it 'returns group data for child group' do
      result = {
        update_path: "/api/v4/groups/#{group.id}",
        shared_runners_availability: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,
        parent_shared_runners_availability: Namespace::SR_ENABLED
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(group)).to eq result
    end
  end

  describe '#group_runners_data_attributes' do
    let(:group) { create(:group) }

    it 'returns group data to render a runner list' do
      data = helper.group_runners_data_attributes(group)

      expect(data[:registration_token]).to eq(group.runners_token)
      expect(data[:group_id]).to eq(group.id)
      expect(data[:group_full_path]).to eq(group.full_path)
      expect(data[:runner_install_help_page]).to eq('https://docs.gitlab.com/runner/install/')
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
        :shared_runners_enabled     | "false"
        :disabled_with_override     | "false"
        :disabled_and_unoverridable | "true"
      end

      with_them do
        it 'returns the override runner status for project with group' do
          group = create(:group, shared_runners_setting)
          project = create(:project, group: group, shared_runners_enabled: false)

          data = helper.toggle_shared_runners_settings_data(project)
          expect(data[:is_disabled_and_unoverridable]).to eq(is_disabled_and_unoverridable)
        end
      end
    end
  end
end
