require 'webmock'

class Spinach::Features::PushRules < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  step 'I should see push rule form' do
    expect(page).to have_selector('input#push_rule_commit_message_regex')
    expect(page).to have_content "Commit message"
    expect(page).to have_content "Commit author's email"
  end
end
