require 'spec_helper'

feature 'Projects > Members > Groups with access list', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  background do
    project.add_master(user)
    @group_link = create(:project_group_link, project: project, group: group)

    sign_in(user)
    visit project_settings_members_path(project)
  end

  scenario 'updates group access level' do
    click_button @group_link.human_access

    page.within '.dropdown-menu' do
      click_link 'Guest'
    end

    wait_for_requests

    visit project_settings_members_path(project)

    expect(first('.group_member')).to have_content('Guest')
  end

  scenario 'updates expiry date' do
    tomorrow = Date.today + 3

    fill_in "member_expires_at_#{group.id}", with: tomorrow.strftime("%F")
    find('body').click
    wait_for_requests

    page.within(find('li.group_member')) do
      expect(page).to have_content('Expires in')
    end
  end

  scenario 'deletes group link' do
    page.within(first('.group_member')) do
      accept_confirm { find('.btn-remove').click }
    end
    wait_for_requests

    expect(page).not_to have_selector('.group_member')
  end

  context 'search in existing members (yes, this filters the groups list as well)' do
    scenario 'finds no results' do
      page.within '.member-search-form' do
        fill_in 'search', with: 'testing 123'
        find('.member-search-btn').click
      end

      expect(page).not_to have_selector('.group_member')
    end

    scenario 'finds results' do
      page.within '.member-search-form' do
        fill_in 'search', with: group.name
        find('.member-search-btn').click
      end

      expect(page).to have_selector('.group_member', count: 1)
    end
  end
end
