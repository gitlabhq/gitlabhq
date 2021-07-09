# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for users' do
  let(:user1) { create(:user, username: 'gob_bluth', name: 'Gob Bluth') }
  let(:user2) { create(:user, username: 'michael_bluth', name: 'Michael Bluth') }
  let(:user3) { create(:user, username: 'gob_2018', name: 'George Oscar Bluth') }

  before do
    sign_in(user1)
  end

  include_examples 'search timeouts', 'users'

  context 'when on the dashboard' do
    it 'finds the user', :js do
      visit dashboard_projects_path

      submit_search('gob')
      select_search_scope('Users')

      page.within('.results') do
        expect(page).to have_content('Gob Bluth')
        expect(page).to have_content('@gob_bluth')
      end
    end
  end

  context 'when on the project page' do
    let(:project) { create(:project) }

    before do
      create(:project_member, :developer, user: user1, project: project)
      create(:project_member, :developer, user: user2, project: project)
      user3
    end

    it 'finds the user belonging to the project' do
      visit project_path(project)

      submit_search('gob')
      select_search_scope('Users')

      page.within('.results') do
        expect(page).to have_content('Gob Bluth')
        expect(page).to have_content('@gob_bluth')

        expect(page).not_to have_content('Michael Bluth')
        expect(page).not_to have_content('@michael_bluth')

        expect(page).not_to have_content('George Oscar Bluth')
        expect(page).not_to have_content('@gob_2018')
      end
    end
  end

  context 'when on the group page' do
    let(:group) { create(:group) }

    before do
      create(:group_member, :developer, user: user1, group: group)
      create(:group_member, :developer, user: user2, group: group)
      user3
    end

    it 'finds the user belonging to the group' do
      visit group_path(group)

      submit_search('gob')
      select_search_scope('Users')

      page.within('.results') do
        expect(page).to have_content('Gob Bluth')
        expect(page).to have_content('@gob_bluth')

        expect(page).not_to have_content('Michael Bluth')
        expect(page).not_to have_content('@michael_bluth')

        expect(page).not_to have_content('George Oscar Bluth')
        expect(page).not_to have_content('@gob_2018')
      end
    end
  end
end
