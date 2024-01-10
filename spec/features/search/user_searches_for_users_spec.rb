# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for users', :js, :clean_gitlab_redis_rate_limiting, feature_category: :global_search do
  let_it_be(:user1) { create(:user, username: 'gob_bluth', name: 'Gob Bluth') }
  let_it_be(:user2) { create(:user, username: 'michael_bluth', name: 'Michael Bluth') }
  let_it_be(:user3) { create(:user, username: 'gob_2018', name: 'George Oscar Bluth') }

  before do
    sign_in(user1)
  end

  include_examples 'search timeouts', 'users' do
    before do
      visit(search_path)
    end
  end

  it 'shows scopes when there is no search term' do
    submit_dashboard_search('')

    within_testid('search-filter') do
      expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
    end
  end

  context 'when on the dashboard' do
    it 'finds the user' do
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
    let_it_be_with_reload(:project) { create(:project) }

    before do
      project.add_developer(user1)
      project.add_developer(user2)
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
      group.add_developer(user1)
      group.add_developer(user2)
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
