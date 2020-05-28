# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Groups with access list', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  before do
    project.add_maintainer(user)
    @group_link = create(:project_group_link, project: project, group: group)

    sign_in(user)
    visit project_project_members_path(project)
  end

  it 'updates group access level' do
    click_button @group_link.human_access

    page.within '.dropdown-menu' do
      click_link 'Guest'
    end

    wait_for_requests

    visit project_project_members_path(project)

    expect(first('.group_member')).to have_content('Guest')
  end

  it 'updates expiry date' do
    tomorrow = Date.today + 3

    fill_in "member_expires_at_#{group.id}", with: tomorrow.strftime("%F")
    find('body').click
    wait_for_requests

    page.within(find('li.group_member')) do
      expect(page).to have_content('Expires in')
    end
  end

  it 'deletes group link' do
    page.within(first('.group_member')) do
      accept_confirm { find('.btn-remove').click }
    end
    wait_for_requests

    expect(page).not_to have_selector('.group_member')
  end

  context 'search in existing members (yes, this filters the groups list as well)' do
    it 'finds no results' do
      page.within '.user-search-form' do
        fill_in 'search', with: 'testing 123'
        find('.user-search-btn').click
      end

      expect(page).not_to have_selector('.group_member')
    end

    it 'finds results' do
      page.within '.user-search-form' do
        fill_in 'search', with: group.name
        find('.user-search-btn').click
      end

      expect(page).to have_selector('.group_member', count: 1)
    end
  end
end
