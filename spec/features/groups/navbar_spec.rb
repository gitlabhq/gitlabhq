# frozen_string_literal: true

require 'spec_helper'

describe 'Group navbar' do
  include NavbarStructureHelper

  include_context 'group navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
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

      insert_after_nav_item(
        _('Kubernetes'),
        new_nav_item: {
          nav_item: _('Packages & Registries'),
          nav_sub_items: [_('Container Registry')]
        }
      )
      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end
end
