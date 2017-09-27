require 'spec_helper'

feature 'Edit group settings', :js do
  given(:user) { create(:user) }
  given(:group) { create(:group, path: 'foo') }

  background do
    group.add_owner(user)
    sign_in(user)
  end

  context 'LDAP sync method' do
    before do
      allow(Gitlab.config.ldap).to receive(:enabled).and_return(true)

      visit group_ldap_group_links_path(group)
    end

    scenario 'shows the LDAP filter section' do
      choose('sync_method_filter')

      expect(page).to have_content('This query must use valid LDAP Search Filter Syntax')
      expect(page).not_to have_content("Synchronize #{group.name}'s members with this LDAP group")
    end

    scenario 'shows the LDAP group section' do
      choose('sync_method_filter') # choose filter first, as group's the default
      choose('sync_method_group')

      expect(page).to have_content("Synchronize #{group.name}'s members with this LDAP group")
      expect(page).not_to have_content('This query must use valid LDAP Search Filter Syntax')
    end
  end
end
