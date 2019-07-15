# frozen_string_literal: true

require 'spec_helper'

describe 'User searches for users' do
  context 'when on the dashboard' do
    it 'finds the user', :js do
      create(:user, username: 'gob_bluth', name: 'Gob Bluth')

      sign_in(create(:user))

      visit dashboard_projects_path

      fill_in 'search', with: 'gob'
      find('#search').send_keys(:enter)

      expect(page).to have_content('Users 1')

      click_on('Users 1')

      expect(page).to have_content('Gob Bluth')
      expect(page).to have_content('@gob_bluth')
    end
  end

  context 'when on the project page' do
    it 'finds the user belonging to the project' do
      project = create(:project)

      user1 = create(:user, username: 'gob_bluth', name: 'Gob Bluth')
      create(:project_member, :developer, user: user1, project: project)

      user2 = create(:user, username: 'michael_bluth', name: 'Michael Bluth')
      create(:project_member, :developer, user: user2, project: project)

      create(:user, username: 'gob_2018', name: 'George Oscar Bluth')

      sign_in(user1)

      visit projects_path(project)

      fill_in 'search', with: 'gob'
      click_button 'Go'

      expect(page).to have_content('Gob Bluth')
      expect(page).to have_content('@gob_bluth')

      expect(page).not_to have_content('Michael Bluth')
      expect(page).not_to have_content('@michael_bluth')

      expect(page).not_to have_content('George Oscar Bluth')
      expect(page).not_to have_content('@gob_2018')
    end
  end

  context 'when on the group page' do
    it 'finds the user belonging to the group' do
      group = create(:group)

      user1 = create(:user, username: 'gob_bluth', name: 'Gob Bluth')
      create(:group_member, :developer, user: user1, group: group)

      user2 = create(:user, username: 'michael_bluth', name: 'Michael Bluth')
      create(:group_member, :developer, user: user2, group: group)

      create(:user, username: 'gob_2018', name: 'George Oscar Bluth')

      sign_in(user1)

      visit group_path(group)

      fill_in 'search', with: 'gob'
      click_button 'Go'

      expect(page).to have_content('Gob Bluth')
      expect(page).to have_content('@gob_bluth')

      expect(page).not_to have_content('Michael Bluth')
      expect(page).not_to have_content('@michael_bluth')

      expect(page).not_to have_content('George Oscar Bluth')
      expect(page).not_to have_content('@gob_2018')
    end
  end
end
