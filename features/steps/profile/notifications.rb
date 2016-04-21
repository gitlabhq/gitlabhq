class Spinach::Features::ProfileNotifications < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  step 'I visit profile notifications page' do
    visit profile_notifications_path
  end

  step 'I should see global notifications settings' do
    expect(page).to have_content "Notifications"
  end

  step 'I select Mention setting from dropdown' do
    select 'mention', from: 'notification_setting_level'
  end

  step 'I should see Notification saved message' do
    page.within '.flash-container' do
      expect(page).to have_content 'Notification settings saved'
    end
  end
end
