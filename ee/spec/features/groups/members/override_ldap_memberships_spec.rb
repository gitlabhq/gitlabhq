require 'spec_helper'

feature 'Groups > Members > Master/Owner can override LDAP access levels' do
  include WaitForRequests

  let(:johndoe)  { create(:user, name: 'John Doe') }
  let(:maryjane) { create(:user, name: 'Mary Jane') }
  let(:owner)    { create(:user) }
  let(:group)    { create(:group_with_ldap_group_link, :public) }
  let(:project)  { create(:project, namespace: group)  }

  let!(:owner_member)   { create(:group_member, :owner, group: group, user: owner) }
  let!(:ldap_member)    { create(:group_member, :guest, group: group, user: johndoe, ldap: true) }
  let!(:regular_member) { create(:group_member, :guest, group: group, user: maryjane, ldap: false) }

  background do
    # We need to actually activate the LDAP config otherwise `Group#ldap_synced?` will always be false!
    allow(Gitlab.config.ldap).to receive_messages(enabled: true)

    sign_in(owner)
  end

  scenario 'override not available on project members page', :js do
    visit namespace_project_project_members_path(group, project)

    expect(page).not_to have_button 'Edit permissions'
  end

  scenario 'owner cannot override LDAP access level', :js do
    stub_application_setting(allow_group_owners_to_manage_ldap: false)

    visit group_group_members_path(group)

    within "#group_member_#{ldap_member.id}" do
      expect(page).not_to have_content 'LDAP'
      expect(page).not_to have_button 'Guest'
      expect(page).not_to have_button 'Edit permissions'
    end
  end

  scenario 'owner can override LDAP access level', :js do
    ldap_override_message = 'John Doe is currently an LDAP user. Editing their permissions will override the settings from the LDAP group sync.'

    visit group_group_members_path(group)

    within "#group_member_#{ldap_member.id}" do
      expect(page).to have_content 'LDAP'
      expect(page).to have_button 'Guest', disabled: true
      expect(page).to have_button 'Edit permissions'

      click_button 'Edit permissions'
    end

    expect(page).to have_content ldap_override_message

    click_button 'Change permissions'

    expect(page).not_to have_content ldap_override_message
    expect(page).not_to have_button 'Change permissions'

    within "#group_member_#{ldap_member.id}" do
      expect(page).not_to have_button 'Edit permissions'
      expect(page).to have_button 'Guest', disabled: false
    end

    refresh # controls should still be enabled after a refresh

    within "#group_member_#{ldap_member.id}" do
      expect(page).not_to have_button 'Edit permissions'
      expect(page).to have_button 'Guest', disabled: false

      click_button 'Guest'

      within '.dropdown-menu' do
        click_link 'Revert to LDAP group sync settings'
      end

      wait_for_requests

      expect(page).to have_button 'Guest', disabled: true
      expect(page).to have_button 'Edit permissions'
    end

    within "#group_member_#{regular_member.id}" do
      expect(page).not_to have_content 'LDAP'
      expect(page).not_to have_button 'Edit permissions'
      expect(page).to have_button 'Guest', disabled: false

      click_button 'Guest'

      within '.dropdown-menu' do
        expect(page).not_to have_content 'Revert to LDAP group sync settings'
      end
    end
  end
end
