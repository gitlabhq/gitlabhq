# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group navbar', :with_license, feature_category: :navigation do
  include NavbarStructureHelper
  include WikiHelpers

  include_context 'group navbar structure'

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }

  before do
    insert_package_nav(_('Kubernetes'))
    insert_after_nav_item(_('Analytics'), new_nav_item: settings_for_maintainer_nav_item) if Gitlab.ee?

    stub_config(dependency_proxy: { enabled: false })
    stub_config(registry: { enabled: false })
    stub_feature_flags(harbor_registry_integration: false)
    stub_feature_flags(observability_group_tab: false)
    stub_group_wikis(false)
    group.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'verified navigation bar' do
    before do
      visit group_path(group)
    end
  end

  context 'when container registry is available' do
    before do
      stub_config(registry: { enabled: true })

      insert_container_nav

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when customer_relations feature is enabled' do
    let(:group) { create(:group, :crm_enabled) }

    before do
      if Gitlab.ee?
        insert_customer_relations_nav(_('Analytics'))
      else
        insert_customer_relations_nav(_('Packages and registries'))
      end

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when customer_relations feature is enabled but subgroup' do
    let(:group) { create(:group, :crm_enabled, parent: create(:group)) }

    before do
      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when dependency proxy is available' do
    before do
      stub_config(dependency_proxy: { enabled: true })

      insert_dependency_proxy_nav

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when harbor registry is available' do
    let(:harbor_integration) { create(:harbor_integration, group: group, project: nil) }

    before do
      group.update!(harbor_integration: harbor_integration)

      stub_feature_flags(harbor_registry_integration: true)

      insert_harbor_registry_nav(_('Package Registry'))

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when observability tab is enabled' do
    before do
      stub_feature_flags(observability_group_tab: true)

      insert_observability_nav

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end
end
