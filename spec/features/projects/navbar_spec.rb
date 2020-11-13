# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar' do
  include NavbarStructureHelper
  include WaitForRequests

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    insert_package_nav(_('Operations'))

    project.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'verified navigation bar' do
    before do
      visit project_path(project)
    end
  end

  context 'when value stream is available' do
    before do
      visit project_path(project)
    end

    it 'redirects to value stream when Analytics item is clicked' do
      page.within('.sidebar-top-level-items') do
        find('[data-qa-selector=analytics_anchor]').click
      end

      wait_for_requests

      expect(page).to have_current_path(project_cycle_analytics_path(project))
    end
  end

  context 'when pages are available' do
    before do
      stub_config(pages: { enabled: true })

      insert_after_sub_nav_item(
        _('Operations'),
        within: _('Settings'),
        new_sub_nav_item_name: _('Pages')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when container registry is available' do
    before do
      stub_config(registry: { enabled: true })

      insert_container_nav(_('Operations'))

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when invite team members is not available' do
    it 'does not display the js-invite-members-trigger' do
      visit project_path(project)

      expect(page).not_to have_selector('.js-invite-members-trigger')
    end
  end

  context 'when invite team members is available' do
    it 'includes the div for js-invite-members-trigger' do
      stub_feature_flags(invite_members_group_modal: true)
      allow_any_instance_of(InviteMembersHelper).to receive(:invite_members_allowed?).and_return(true)

      visit project_path(project)

      expect(page).to have_selector('.js-invite-members-trigger')
    end
  end
end
