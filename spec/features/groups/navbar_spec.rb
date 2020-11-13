# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group navbar' do
  include NavbarStructureHelper
  include WikiHelpers

  include_context 'group navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:structure) do
    [
      {
        nav_item: _('Group overview'),
        nav_sub_items: [
          _('Details'),
          _('Activity')
        ]
      },
      {
        nav_item: _('Issues'),
        nav_sub_items: [
          _('List'),
          _('Board'),
          _('Labels'),
          _('Milestones')
        ]
      },
      {
        nav_item: _('Merge Requests'),
        nav_sub_items: []
      },
      (push_rules_nav_item if Gitlab.ee?),
      {
        nav_item: _('Kubernetes'),
        nav_sub_items: []
      },
      (analytics_nav_item if Gitlab.ee?),
      {
        nav_item: _('Members'),
        nav_sub_items: []
      }
    ]
  end

  before do
    insert_package_nav(_('Kubernetes'))

    stub_feature_flags(group_iterations: false)
    stub_config(dependency_proxy: { enabled: false })
    stub_config(registry: { enabled: false })
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

      insert_container_nav(_('Kubernetes'))

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when dependency proxy is available' do
    before do
      stub_config(dependency_proxy: { enabled: true })

      insert_dependency_proxy_nav(_('Dependency Proxy'))

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when invite team members is not available' do
    it 'does not display the js-invite-members-trigger' do
      visit group_path(group)

      expect(page).not_to have_selector('.js-invite-members-trigger')
    end
  end
end
