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

  describe '#cascading_namespace_settings_tooltip_data' do
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
