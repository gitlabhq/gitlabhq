require 'webmock'

class Spinach::Features::GitHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  
  step 'I should see git hook form' do
    page.should have_selector('input#git_hook_commit_message_regex')
    page.should have_content "Commit message"
    page.should have_content "Commit author's email"
  end

 
end
