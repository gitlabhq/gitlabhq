class Spinach::Features::AdminApplications < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I click on new application button' do
    click_on 'New Application'
  end

  step 'I should see application form' do
    page.should have_content "New application"
  end

  step 'I fill application form out and submit' do
    fill_in :doorkeeper_application_name, with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    click_on "Submit"
  end

  step 'I see application' do
    page.should have_content "Application: test"
    page.should have_content "Application Id"
    page.should have_content "Secret"
  end

  step 'I click edit' do
    click_on "Edit"
  end

  step 'I see edit application form' do
    page.should have_content "Edit application"
  end

  step 'I change name of application and submit' do
    page.should have_content "Edit application"
    fill_in :doorkeeper_application_name, with: 'test_changed'
    click_on "Submit"
  end

  step 'I see that application was changed' do
    page.should have_content "test_changed"
    page.should have_content "Application Id"
    page.should have_content "Secret"
  end

  step 'I click to remove application' do
    within '.oauth-applications' do
      click_on "Destroy"
    end
  end

  step "I see that application is removed" do
    page.find(".oauth-applications").should_not have_content "test_changed"
  end
end
