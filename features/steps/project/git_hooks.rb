require 'webmock'

class Spinach::Features::GitHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  
  step 'I should see git hook form' do
    expect(page).to have_selector('input#git_hook_commit_message_regex')
    expect(page).to have_content "Commit message"
    expect(page).to have_content "Commit author's email"
  end

 
end
