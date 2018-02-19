require 'spec_helper'

describe 'Admin Dashboard' do
  describe 'Users statistic' do
    before do
      project1 = create(:project_empty_repo)
      project1.add_reporter(create(:user))

      project2 = create(:project_empty_repo)
      project2.add_developer(create(:user))

      # Add same user as Reporter and Developer to different projects
      # and expect it to be counted once for the stats
      user = create(:user)
      project1.add_reporter(user)
      project2.add_developer(user)

      sign_in(create(:admin))
    end

    describe 'Roles stats' do
      it 'show correct amount of users per role' do
        visit admin_dashboard_stats_path

        expect(page).to have_content('Admin users 1')
        expect(page).to have_content('Users with highest role developer 2')
        expect(page).to have_content('Users with highest role reporter 1')
      end
    end
  end
end
