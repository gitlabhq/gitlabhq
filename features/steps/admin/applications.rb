class Spinach::Features::AdminApplications < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I click on new application button' do
    click_on 'New Application'
  end

  step 'I should see application form' do
    expect(page).to have_content "New application"
  end

  step 'I fill application form out and submit' do
    fill_in :doorkeeper_application_name, with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    click_on "Submit"
  end

  step 'I see application' do
    expect(page).to have_content "Application: test"
    expect(page).to have_content "Application Id"
    expect(page).to have_content "Secret"
  end

  step 'I click edit' do
    click_on "Edit"
  end

  step 'I see edit application form' do
    expect(page).to have_content "Edit application"
  end

  step 'I change name of application and submit' do
    expect(page).to have_content "Edit application"
    fill_in :doorkeeper_application_name, with: 'test_changed'
    click_on "Submit"
  end

  step 'I see that application was changed' do
    expect(page).to have_content "test_changed"
    expect(page).to have_content "Application Id"
    expect(page).to have_content "Secret"
  end

  step 'I click to remove application' do
    page.within '.oauth-applications' do
      click_on "Destroy"
    end
  end

  step "I see that application is removed" do
    expect(page.find(".oauth-applications")).not_to have_content "test_changed"
  end
end
