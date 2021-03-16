# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin visits dashboard' do
  include ProjectForksHelper

  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'counting forks', :js do
    it 'correctly counts 2 forks of a project' do
      project = create(:project)
      project_fork = fork_project(project)
      fork_project(project_fork)

      # Make sure the fork_networks & fork_networks reltuples have been updated
      # to get a correct count on postgresql
      ActiveRecord::Base.connection.execute('ANALYZE fork_networks')
      ActiveRecord::Base.connection.execute('ANALYZE fork_network_members')

      visit admin_root_path

      expect(page).to have_content('Forks 2')
    end
  end

  describe 'Users statistic' do
    let_it_be(:users_statistics) { create(:users_statistics) }

    it 'shows correct amounts of users', :aggregate_failures do
      visit admin_dashboard_stats_path

      expect(page).to have_content('Users without a Group and Project 23')
      expect(page).to have_content('Users with highest role Guest 5')
      expect(page).to have_content('Users with highest role Reporter 9')
      expect(page).to have_content('Users with highest role Developer 21')
      expect(page).to have_content('Users with highest role Maintainer 6')
      expect(page).to have_content('Users with highest role Owner 5')
      expect(page).to have_content('Bots 2')

      if Gitlab.ee?
        expect(page).to have_content('Billable users 69')
      else
        expect(page).not_to have_content('Billable users 69')
      end

      expect(page).to have_content('Blocked users 7')
      expect(page).to have_content('Total users 78')
      expect(page).to have_content('Active users 71')
    end
  end
end
