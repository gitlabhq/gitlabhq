require 'webmock'

class ProjectHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  step 'project has hook' do
    @hook = create(:project_hook, project: current_project)
  end

  step 'I own empty project with hook' do
    @project = create(:empty_project,
                      name: 'Empty Project', namespace: @user.namespace)
    @hook = create(:project_hook, project: current_project)
  end

  step 'I should see project hook' do
    page.should have_content @hook.url
  end

  step 'I submit new hook' do
    @url = Faker::Internet.uri("http")
    fill_in "hook_url", with: @url
    expect { click_button "Add Web Hook" }.to change(ProjectHook, :count).by(1)
  end

  step 'I should see newly created hook' do
    page.current_path.should == project_hooks_path(current_project)
    page.should have_content(@url)
  end

  step 'I click test hook button' do
    stub_request(:post, @hook.url).to_return(status: 200)
    click_link 'Test Hook'
  end

  step 'I click test hook button with invalid URL' do
    stub_request(:post, @hook.url).to_raise(SocketError)
    click_link 'Test Hook'
  end

  step 'hook should be triggered' do
    page.current_path.should == project_hooks_path(current_project)
    page.should have_selector '.flash-notice',
                              text: 'Hook successfully executed.'
  end

  step 'I should see hook error message' do
    page.should have_selector '.flash-alert',
                              text: 'Hook execution failed. '\
                              'Ensure the project has commits.'
  end

  step 'I should see hook service down error message' do
    page.should have_selector '.flash-alert',
                              text: 'Hook execution failed. '\
                                    'Ensure hook URL is correct and '\
                                    'service is up.'
  end
end
