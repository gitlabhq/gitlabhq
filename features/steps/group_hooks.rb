require 'webmock'

class Spinach::Features::GroupHooks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RSpec::Matchers
  include RSpec::Mocks::ExampleMethods
  include WebMock::API

  step 'I own group "Sourcing"' do
    @group = create :group, name: "Sourcing"
    @group.add_owner(current_user)
  end

  step 'I own project "Shop" in group "Sourcing"' do
    @project = create(:project,
                      name: 'Shop', group: @group)
  end

  step 'I own empty project "Empty Shop" in group "Sourcing"' do
    @project = create(:empty_project,
                      name: 'Shop', group: @group)
  end

  step 'group has hook' do
    @hook = create(:group_hook, group: @group)
  end

  step 'I should see group hook' do
    expect(page).to have_content @hook.url
  end

  step 'I submit new hook' do
    @url = FFaker::Internet.uri("http")
    fill_in "hook_url", with: @url
    expect { click_button "Add Webhook" }.to change(GroupHook, :count).by(1)
  end

  step 'I should see newly created hook' do
    expect(current_path).to eq group_hooks_path(@group)
    expect(page).to have_content(@url)
  end

  step 'I click test hook button' do
    stub_request(:post, @hook.url).to_return(status: 200)
    click_link 'Test'
  end

  step 'I click test hook button with invalid URL' do
    stub_request(:post, @hook.url).to_raise(SocketError)
    click_link 'Test'
  end

  step 'hook should be triggered' do
    expect(current_path).to eq group_hooks_path(@group)
    expect(page).to have_selector '.flash-notice',
                              text: 'Hook successfully executed.'
  end

  step 'I should see hook error message' do
    expect(page).to have_selector '.flash-alert',
                              text: 'Hook execution failed. Ensure the group has a project with commits.'
  end

  step 'I should see hook service down error message' do
    expect(page).to have_selector '.flash-alert',
                              text: 'Hook execution failed: Exception from'
  end
end
