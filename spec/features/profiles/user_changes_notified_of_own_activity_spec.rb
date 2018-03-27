require 'spec_helper'

feature 'Profile > Notifications > User changes notified_of_own_activity setting', :js do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario 'User opts into receiving notifications about their own activity' do
    visit profile_notifications_path

    expect(page).not_to have_checked_field('user[notified_of_own_activity]')

    check 'user[notified_of_own_activity]'

    expect(page).to have_content('Notification settings saved')
    expect(page).to have_checked_field('user[notified_of_own_activity]')
  end

  scenario 'User opts out of receiving notifications about their own activity' do
    user.update!(notified_of_own_activity: true)
    visit profile_notifications_path

    expect(page).to have_checked_field('user[notified_of_own_activity]')

    uncheck 'user[notified_of_own_activity]'

    expect(page).to have_content('Notification settings saved')
    expect(page).not_to have_checked_field('user[notified_of_own_activity]')
  end
end
