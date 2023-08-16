# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Notifications > User changes notified_of_own_activity setting', :js,
  feature_category: :user_profile do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'user opts into receiving notifications about their own activity' do
    visit profile_notifications_path

    expect(page).not_to have_checked_field('user[notified_of_own_activity]')

    check 'user[notified_of_own_activity]'

    expect(page).to have_content('Notification settings saved')
    expect(page).to have_checked_field('user[notified_of_own_activity]')
  end

  it 'user opts out of receiving notifications about their own activity' do
    user.update!(notified_of_own_activity: true)
    visit profile_notifications_path

    expect(page).to have_checked_field('user[notified_of_own_activity]')

    uncheck 'user[notified_of_own_activity]'

    expect(page).to have_content('Notification settings saved')
    expect(page).not_to have_checked_field('user[notified_of_own_activity]')
  end
end
