# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespacesHelper, feature_category: :groups_and_projects do
  let!(:admin) { create(:admin) }
  let!(:admin_project_creation_level) { nil }
  let!(:admin_group) do
    create(:group, :private, project_creation_level: admin_project_creation_level)
  end

  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }
  let!(:user_group) do
    create(:group, :private, project_creation_level: user_project_creation_level)
  end

  let!(:subgroup1) do
    create(:group, :private, parent: admin_group, project_creation_level: nil)
  end

  let!(:subgroup2) do
    create(
      :group,
      :private,
      parent: admin_group,
      project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
    )
  end

  let!(:subgroup3) do
    create(
      :group,
      :private,
      parent: admin_group,
      project_creation_level: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS
    )
  end

  before do
    admin_group.add_owner(admin)
    user_group.add_owner(user)
  end

  describe '#check_group_lock' do
    attribute = :math_rendering_limits_enabled

    context 'when the method exists on namespace_settings' do
      it 'calls the method on namespace_settings' do
        expect(subgroup1.namespace_settings).to receive(attribute).and_return(true)
        expect(helper.check_group_lock(subgroup1, attribute)).to be true
      end
    end

    context 'when the method does not exist on namespace_settings' do
      it 'returns false' do
        expect(helper.check_group_lock(subgroup1, :non_existent_method)).to be false
      end
    end
  end

  describe '#check_project_lock' do
    let(:project) { build(:project, group: subgroup1) }

    attribute = :math_rendering_limits_enabled

    it 'returns true when the method exists and returns true' do
      allow(project.project_setting).to receive(attribute).and_return(true)
      expect(helper.check_project_lock(project, attribute)).to be true
    end

    it 'returns false when the method does not exist' do
      expect(helper.check_project_lock(project, :non_existent_method)).to be false
    end
  end

  describe '#cascading_namespace_settings_tooltip_data' do
    attribute = :math_rendering_limits_enabled

    it 'returns tooltip data with testid' do
      allow(helper).to receive(:cascading_namespace_settings_tooltip_raw_data).and_return({ key: 'value' })
      result = helper.cascading_namespace_settings_tooltip_data(attribute, subgroup1, -> {})
      expect(result[:tooltip_data]).to eq('{"key":"value"}')
      expect(result[:testid]).to eq('cascading-settings-lock-icon')
    end
  end

  describe '#cascading_namespace_settings_tooltip_raw_data' do
    attribute = :math_rendering_limits_enabled

    subject do
      helper.cascading_namespace_settings_tooltip_data(
        attribute,
        subgroup1,
        ->(locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') }
      )
    end

    context 'when locked by an application setting' do
      before do
        allow(subgroup1.namespace_settings).to receive("#{attribute}_locked_by_application_setting?").and_return(true)
        allow(subgroup1.namespace_settings).to receive("#{attribute}_locked_by_ancestor?").and_return(false)
      end

      it 'returns expected hash' do
        expect(subject).to match({
          tooltip_data: {
            locked_by_application_setting: true,
            locked_by_ancestor: false
          }.to_json,
          testid: 'cascading-settings-lock-icon'
        })
      end
    end

    context 'when locked by an ancestor namespace' do
      before do
        allow(subgroup1.namespace_settings).to receive("#{attribute}_locked_by_application_setting?").and_return(false)
        allow(subgroup1.namespace_settings).to receive("#{attribute}_locked_by_ancestor?").and_return(true)
        allow(subgroup1.namespace_settings).to receive("#{attribute}_locked_ancestor").and_return(admin_group.namespace_settings)
      end

      it 'returns expected hash' do
        expect(subject).to match({
          tooltip_data: {
            locked_by_application_setting: false,
            locked_by_ancestor: true,
            ancestor_namespace: {
              full_name: admin_group.full_name,
              path: edit_group_path(admin_group, anchor: 'js-permissions-settings')
            }
          }.to_json,
          testid: 'cascading-settings-lock-icon'
        })
      end
    end
  end

  describe '#project_cascading_namespace_settings_tooltip_data' do
    let(:project) { build(:project, group: subgroup1) }

    attribute = :math_rendering_limits_enabled
    settings_path_helper = ->(locked_ancestor) { edit_group_path(locked_ancestor) }
    subject { helper.project_cascading_namespace_settings_tooltip_data(attribute, project, settings_path_helper) }

    context 'when not locked by ancestor' do
      before do
        allow(helper).to receive(:cascading_namespace_settings_tooltip_data)
        .and_return(tooltip_data: { locked_by_ancestor: false }.to_json)
      end

      context 'when locked by project group' do
        before do
          allow(project.project_setting).to receive("#{attribute}_locked?").and_return(true)
        end

        it 'returns JSON with locked_by_ancestor true and ancestor_namespace object' do
          result = Gitlab::Json.parse(subject)
          expect(result['locked_by_ancestor']).to be true
          expect(result['ancestor_namespace']).to eq({
            'full_name' => project.group.name,
            'path' => edit_group_path(project.group)
          })
        end
      end

      context 'when not locked by project group' do
        before do
          allow(project.project_setting).to receive("#{attribute}_locked").and_return(false)
        end

        it 'returns JSON without changing locked_by_ancestor' do
          expect(Gitlab::Json.parse(subject)['locked_by_ancestor']).to be false
          expect(Gitlab::Json.parse(subject)).not_to have_key('ancestor_namespace')
        end
      end
    end

    context 'when locked by ancestor' do
      before do
        allow(helper).to receive(:cascading_namespace_settings_tooltip_raw_data)
          .and_return({ locked_by_ancestor: true })
      end

      it 'returns JSON without changing locked_by_ancestor' do
        expect(Gitlab::Json.parse(subject)['locked_by_ancestor']).to be true
        expect(Gitlab::Json.parse(subject)).not_to have_key('ancestor_namespace')
      end
    end
  end

  describe '#cascading_namespace_setting_locked?' do
    let(:attribute) { :math_rendering_limits_enabled }

    context 'when `group` argument is `nil`' do
      it 'returns `false`' do
        expect(helper.cascading_namespace_setting_locked?(attribute, nil)).to eq(false)
      end
    end

    context 'when `*_locked?` method does not exist' do
      it 'returns `false`' do
        expect(helper.cascading_namespace_setting_locked?(:attribute_that_does_not_exist, admin_group)).to eq(false)
      end
    end

    context 'when `*_locked?` method does exist' do
      before do
        allow(admin_group.namespace_settings).to receive(:"#{attribute}_locked?").and_return(true)
      end

      it 'calls corresponding `*_locked?` method' do
        helper.cascading_namespace_setting_locked?(attribute, admin_group, include_self: true)

        expect(admin_group.namespace_settings).to have_received(:"#{attribute}_locked?").with(include_self: true)
      end
    end
  end

  describe '#pipeline_usage_app_data', unless: Gitlab.ee?, feature_category: :consumables_cost_management do
    it 'returns a hash with necessary data for the frontend' do
      expect(helper.pipeline_usage_app_data(user_group)).to eql({
        namespace_actual_plan_name: user_group.actual_plan_name,
        namespace_path: user_group.full_path,
        namespace_id: user_group.id,
        user_namespace: user_group.user_namespace?.to_s,
        page_size: Kaminari.config.default_per_page
      })
    end
  end
end
