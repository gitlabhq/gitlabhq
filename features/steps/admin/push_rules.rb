require 'webmock'

class Spinach::Features::AdminPushRulesSample < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  step 'I fill in a form and submit' do
    fill_in "Commit message", with: "my_string"
    click_button "Save Push Rules"
  end

  step 'I see my push rule saved' do
    visit admin_push_rules_path
    expect(page).to have_selector("input[value='my_string']")
  end
end
