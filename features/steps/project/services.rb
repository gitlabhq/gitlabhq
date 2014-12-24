class Spinach::Features::ProjectServices < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I visit project "Shop" services page' do
    visit project_services_path(@project)
  end

  step 'I should see list of available services' do
    expect(page).to have_content 'Project services'
    expect(page).to have_content 'Campfire'
    expect(page).to have_content 'HipChat'
    expect(page).to have_content 'GitLab CI'
    expect(page).to have_content 'Assembla'
    expect(page).to have_content 'Pushover'
    expect(page).to have_content 'Atlassian Bamboo'
  end

  step 'I click gitlab-ci service link' do
    click_link 'GitLab CI'
  end

  step 'I fill gitlab-ci settings' do
    check 'Active'
    fill_in 'Project url', with: 'http://ci.gitlab.org/projects/3'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see service settings saved' do
    expect(find_field('Project url').value).to eq('http://ci.gitlab.org/projects/3')
  end

  step 'I click hipchat service link' do
    click_link 'HipChat'
  end

  step 'I fill hipchat settings' do
    check 'Active'
    fill_in 'Room', with: 'gitlab'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see hipchat service settings saved' do
    expect(find_field('Room').value).to eq('gitlab')
  end

  step 'I fill hipchat settings with custom server' do
    check 'Active'
    fill_in 'Room', with: 'gitlab_custom'
    fill_in 'Token', with: 'secretCustom'
    fill_in 'Server', with: 'https://chat.example.com'
    click_button 'Save'
  end

  step 'I should see hipchat service settings with custom server saved' do
    expect(find_field('Server').value).to eq('https://chat.example.com')
  end

  step 'I click pivotaltracker service link' do
    click_link 'PivotalTracker'
  end

  step 'I fill pivotaltracker settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see pivotaltracker service settings saved' do
    expect(find_field('Token').value).to eq('verySecret')
  end

  step 'I click Flowdock service link' do
    click_link 'Flowdock'
  end

  step 'I fill Flowdock settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see Flowdock service settings saved' do
    expect(find_field('Token').value).to eq('verySecret')
  end

  step 'I click Assembla service link' do
    click_link 'Assembla'
  end

  step 'I fill Assembla settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see Assembla service settings saved' do
    expect(find_field('Token').value).to eq('verySecret')
  end

  step 'I click email on push service link' do
    click_link 'Emails on push'
  end

  step 'I fill email on push settings' do
    fill_in 'Recipients', with: 'qa@company.name'
    click_button 'Save'
  end

  step 'I should see email on push service settings saved' do
    expect(find_field('Recipients').value).to eq('qa@company.name')
  end

  step 'I click Slack service link' do
    click_link 'Slack'
  end

  step 'I fill Slack settings' do
    check 'Active'
    fill_in 'Webhook', with: 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685'
    click_button 'Save'
  end

  step 'I should see Slack service settings saved' do
    expect(find_field('Webhook').value).to eq('https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685')
  end

  step 'I click Pushover service link' do
    click_link 'Pushover'
  end

  step 'I fill Pushover settings' do
    check 'Active'
    fill_in 'Api key', with: 'verySecret'
    fill_in 'User key', with: 'verySecret'
    fill_in 'Device', with: 'myDevice'
    select 'High Priority', from: 'Priority'
    select 'Bike', from: 'Sound'
    click_button 'Save'
  end

  step 'I should see Pushover service settings saved' do
    expect(find_field('Api key').value).to eq('verySecret')
    expect(find_field('User key').value).to eq('verySecret')
    expect(find_field('Device').value).to eq('myDevice')
    expect(find_field('Priority').find('option[selected]').value).to eq('1')
    expect(find_field('Sound').find('option[selected]').value).to eq('bike')
  end

  step 'I click Atlassian Bamboo CI service link' do
    click_link 'Atlassian Bamboo CI'
  end

  step 'I fill Atlassian Bamboo CI settings' do
    check 'Active'
    fill_in 'Bamboo url', with: 'http://bamboo.example.com'
    fill_in 'Build key', with: 'KEY'
    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see Atlassian Bamboo CI service settings saved' do
    expect(find_field('Bamboo url').value).to eq('http://bamboo.example.com')
    expect(find_field('Build key').value).to eq('KEY')
    expect(find_field('Username').value).to eq('user')
  end
end
