require 'spec_helper'

describe 'Admin Dashboard' do
  describe 'Users statistic' do
    before do
      3.times do
        project = create(:project)
        user = create(:user)
        project.add_reporter(user)
      end

      2.times do
        project = create(:project)
        user = create(:user)
        project.add_developer(user)
      end

      # Add same user as Reporter and Developer to different projects
      # and expect it to be counted once for the stats
      user = create(:user)
      project1 = Project.first
      project2 = Project.last
      project1.add_reporter(user)
      project2.add_developer(user)

      sign_in(create(:admin))
    end

    describe 'Roles stats' do
      it 'show correct amount of users per role' do
        visit admin_dashboard_stats_path

        expect(page).to have_content('Admin users 1')
        expect(page).to have_content('Users with highest role developer 3')
        expect(page).to have_content('Users with highest role reporter 3')
      end
    end
  end
end
