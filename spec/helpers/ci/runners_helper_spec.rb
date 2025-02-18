# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersHelper, feature_category: :fleet_visibility do
  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:non_admin_user) { create(:user) }
  let_it_be(:user) { non_admin_user }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#runner_status_icon', :clean_gitlab_redis_cache do
    it "returns online text" do
      runner = create(:ci_runner, contacted_at: 1.second.ago)
      expect(helper.runner_status_icon(runner)).to include("is online")
    end

    it "returns never contacted" do
      runner = create(:ci_runner, :unregistered)
      expect(helper.runner_status_icon(runner)).to include("never contacted")
    end

    it "returns offline text" do
      runner = create(:ci_runner, :offline)
      expect(helper.runner_status_icon(runner)).to include("is offline")
    end

    it "returns stale text" do
      runner = create(:ci_runner, :stale)
      expect(helper.runner_status_icon(runner)).to include("is stale")
      expect(helper.runner_status_icon(runner)).to include("last contact was")
    end

    it "returns stale text, when runner never contacted" do
      runner = create(:ci_runner, :unregistered, :stale)
      expect(helper.runner_status_icon(runner)).to include("is stale")
      expect(helper.runner_status_icon(runner)).to include("never contacted")
    end
  end

  describe '#runner_short_name' do
    it 'shows runner short name' do
      runner = build_stubbed(:ci_runner, id: non_existing_record_id)

      expect(helper.runner_short_name(runner)).to eq("##{runner.id} (#{runner.short_sha})")
    end
  end

  describe '#admin_runners_app_data', :enable_admin_mode do
    let_it_be(:user) { admin_user }

    subject(:data) { helper.admin_runners_app_data }

    it 'returns correct data' do
      expect(data).to include(
        runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
        new_runner_path: '/admin/runners/new',
        allow_registration_token: 'true',
        registration_token: Gitlab::CurrentSettings.runners_registration_token,
        online_contact_timeout_secs: 7200,
        stale_timeout_secs: 604800,
        tag_suggestions_path: '/admin/runners/tag_list.json',
        can_admin_runners: 'true'
      )
    end

    context 'when current user is not an admin' do
      let_it_be(:user) { non_admin_user }

      it 'returns the correct data' do
        expect(data).to include(
          registration_token: nil,
          can_admin_runners: 'false'
        )
      end
    end
  end

  describe '#group_shared_runners_settings_data' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent, shared_runners_enabled: false) }
    let_it_be(:group_with_project) { create(:group, parent: parent) }
    let_it_be(:project) { create(:project, group: group_with_project) }

    let(:runner_constants) do
      {
        runner_enabled_value: Namespace::SR_ENABLED,
        runner_disabled_value: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,
        runner_allow_override_value: Namespace::SR_DISABLED_AND_OVERRIDABLE
      }
    end

    before do
      allow(helper).to receive(:can?).with(user, :admin_group, parent).and_return(true)
    end

    it 'returns group data for top level group' do
      result = {
        group_id: parent.id,
        group_name: parent.name,
        group_is_empty: 'false',
        shared_runners_setting: Namespace::SR_ENABLED,

        parent_name: nil,
        parent_settings_path: nil,
        parent_shared_runners_setting: nil
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(parent)).to eq result
    end

    it 'returns group data for child group' do
      result = {
        group_id: group.id,
        group_name: group.name,
        group_is_empty: 'true',
        shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,

        parent_shared_runners_setting: Namespace::SR_ENABLED,
        parent_name: parent.name,
        parent_settings_path: group_settings_ci_cd_path(group.parent, anchor: 'runners-settings')
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(group)).to eq result
    end

    it 'returns groups data for child group with no access to parent' do
      allow(helper).to receive(:can?).with(user, :admin_group, parent).and_return(false)

      result = {
        group_id: group.id,
        group_name: group.name,
        group_is_empty: 'true',
        shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,

        parent_shared_runners_setting: Namespace::SR_ENABLED,
        parent_name: nil,
        parent_settings_path: nil
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(group)).to eq result
    end

    it 'returns group data for child group with project' do
      result = {
        group_id: group_with_project.id,
        group_name: group_with_project.name,
        group_is_empty: 'false',
        shared_runners_setting: Namespace::SR_ENABLED,

        parent_shared_runners_setting: Namespace::SR_ENABLED,
        parent_name: parent.name,
        parent_settings_path: group_settings_ci_cd_path(group.parent, anchor: 'runners-settings')
      }.merge(runner_constants)

      expect(helper.group_shared_runners_settings_data(group_with_project)).to eq result
    end
  end

  describe '#group_runners_data_attributes' do
    let(:group) { create(:group) }

    context 'when user can register group runners' do
      before do
        allow(helper).to receive(:can?).with(user, :register_group_runners, group).and_return(true)
      end

      it 'returns group data to render a runner list' do
        expect(helper.group_runners_data_attributes(group)).to include(
          group_id: group.id,
          group_full_path: group.full_path,
          runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
          online_contact_timeout_secs: 7200,
          stale_timeout_secs: 604800
        )
      end
    end

    context 'when user cannot register group runners' do
      before do
        allow(helper).to receive(:can?).with(user, :register_group_runners, group).and_return(false)
      end

      it 'returns empty registration token' do
        expect(helper.group_runners_data_attributes(group)).not_to include(registration_token: group.runners_token)
      end
    end
  end

  describe '#toggle_shared_runners_settings_data' do
    let_it_be(:group) { create(:group) }

    let(:project_with_runners) { create(:project, namespace: group, shared_runners_enabled: true) }
    let(:project_without_runners) { create(:project, namespace: group, shared_runners_enabled: false) }

    context 'when project has runners' do
      it 'returns the correct value for is_enabled' do
        allow(helper).to receive(:can?).with(user, :admin_group, group).and_return(false)

        data = helper.toggle_shared_runners_settings_data(project_with_runners)

        expect(data).to include(
          is_enabled: 'true',
          group_name: nil,
          group_settings_path: nil
        )
      end
    end

    context 'when group can be configured by user' do
      it 'returns values to configure group' do
        allow(helper).to receive(:can?).with(user, :admin_group, group).and_return(true)

        data = helper.toggle_shared_runners_settings_data(project_with_runners)

        expect(data).to include(
          group_name: group.name,
          group_settings_path: group_settings_ci_cd_path(group, anchor: 'runners-settings')
        )
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
        :shared_runners_enabled                    | "false"
        :shared_runners_disabled_and_overridable   | "false"
        :shared_runners_disabled_and_unoverridable | "true"
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
