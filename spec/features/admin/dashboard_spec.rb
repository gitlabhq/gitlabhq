# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin visits dashboard' do
  include ProjectForksHelper

  before do
    admin = create(:admin)
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  context 'counting forks', :js, feature_category: :source_code_management do
    it 'correctly counts 2 forks of a project' do
      project = create(:project)
      project_fork = fork_project(project)
      fork_project(project_fork)

      # Make sure the fork_networks & fork_networks reltuples have been updated
      # to get a correct count on postgresql
      ForkNetwork.connection.execute('ANALYZE fork_networks')
      ForkNetwork.connection.execute('ANALYZE fork_network_members')

      visit admin_root_path

      expect(page).to have_content('Forks 2')
    end
  end

  describe 'Users statistic', feature_category: :user_management do
    let_it_be(:users_statistics) { create(:users_statistics) }

    it 'shows correct amounts of users', :aggregate_failures do
      visit admin_dashboard_stats_path

      expect(page).to have_content('Users without a Group and Project 23')
      expect(page).to have_content('Users with highest role Guest 5')
      expect(page).to have_content('Users with highest role Planner 7')
      expect(page).to have_content('Users with highest role Reporter 9')
      expect(page).to have_content('Users with highest role Developer 21')
      expect(page).to have_content('Users with highest role Maintainer 6')
      expect(page).to have_content('Users with highest role Owner 5')
      expect(page).to have_content('Bots 2')

      if Gitlab.ee?
        expect(page).to have_content('Billable users 76')
      else
        expect(page).not_to have_content('Billable users 76')
      end

      expect(page).to have_content('Blocked users 7')
      expect(page).to have_content('Total users (active users + blocked users) 85')
    end
  end

  describe 'Version check', :js, feature_category: :deployment_management do
    it 'shows badge on CE' do
      visit admin_root_path

      page.within('.admin-dashboard') do
        expect(find_by_testid('check-version-badge')).to have_content('Up to date')
      end
    end
  end
end
