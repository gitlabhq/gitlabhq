require 'webmock'

class ProjectHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  Given 'project has hook' do
    @hook = create(:project_hook, project: current_project)
  end

  Then 'I should see project hook' do
    page.should have_content @hook.url
  end

  When 'I submit new hook' do
    @url = Faker::Internet.uri("http")
    fill_in "hook_url", with: @url
    expect { click_button "Add Web Hook" }.to change(ProjectHook, :count).by(1)
  end

  Then 'I should see newly created hook' do
    page.current_path.should == project_hooks_path(current_project)
    page.should have_content(@url)
  end

  When 'I click test hook button' do
    stub_request(:post, @hook.url).to_return(status: 200)
    click_link 'Test Hook'
  end

  Then 'hook should be triggered' do
    page.current_path.should == project_hooks_path(current_project)
  end
end
