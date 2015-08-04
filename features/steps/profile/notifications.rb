class Spinach::Features::ProfileNotifications < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  step 'I visit profile notifications page' do
    visit profile_notifications_path
  end

  step 'I should see global notifications settings' do
    expect(page).to have_content "Notifications"
  end
end
