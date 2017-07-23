class Spinach::Features::ProjectServices < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I visit project "Shop" services page' do
    visit project_settings_integrations_path(@project)
  end

  step 'I should see list of available services' do
    expect(page).to have_content 'Project services'
    expect(page).to have_content 'Campfire'
    expect(page).to have_content 'HipChat'
    expect(page).to have_content 'Assembla'
    expect(page).to have_content 'Pushover'
    expect(page).to have_content 'Atlassian Bamboo'
    expect(page).to have_content 'JetBrains TeamCity'
    expect(page).to have_content 'Asana'
    expect(page).to have_content 'Irker (IRC gateway)'
  end

  step 'I should see service settings saved' do
    expect(find_field('Active').value).to eq '1'
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

  step 'I should see the Hipchat success message' do
    expect(page).to have_content 'HipChat activated.'
  end

  step 'I fill hipchat settings with custom server' do
    check 'Active'
    fill_in 'Room', with: 'gitlab_custom'
    fill_in 'Token', with: 'secretCustom'
    fill_in 'Server', with: 'https://chat.example.com'
    click_button 'Save'
  end

  step 'I click pivotaltracker service link' do
    click_link 'PivotalTracker'
  end

  step 'I fill pivotaltracker settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see the Pivotaltracker success message' do
    expect(page).to have_content 'PivotalTracker activated.'
  end

  step 'I click Flowdock service link' do
    click_link 'Flowdock'
  end

  step 'I fill Flowdock settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see the Flowdock success message' do
    expect(page).to have_content 'Flowdock activated.'
  end

  step 'I click Assembla service link' do
    click_link 'Assembla'
  end

  step 'I fill Assembla settings' do
    check 'Active'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see the Assembla success message' do
    expect(page).to have_content 'Assembla activated.'
  end

  step 'I click Asana service link' do
    click_link 'Asana'
  end

  step 'I fill Asana settings' do
    check 'Active'
    fill_in 'Api key', with: 'verySecret'
    fill_in 'Restrict to branch', with: 'master'
    click_button 'Save'
  end

  step 'I should see the Asana success message' do
    expect(page).to have_content 'Asana activated.'
  end

  step 'I click email on push service link' do
    click_link 'Emails on push'
  end

  step 'I fill email on push settings' do
    check 'Active'
    fill_in 'Recipients', with: 'qa@company.name'
    click_button 'Save'
  end

  step 'I should see the Emails on push success message' do
    expect(page).to have_content 'Emails on push activated.'
  end

  step 'I click Irker service link' do
    click_link 'Irker (IRC gateway)'
  end

  step 'I fill Irker settings' do
    check 'Active'
    fill_in 'Recipients', with: 'irc://chat.freenode.net/#commits'
    check 'Colorize messages'
    click_button 'Save'
  end

  step 'I should see the Irker success message' do
    expect(page).to have_content 'Irker (IRC gateway) activated.'
  end

  step 'I click Slack notifications service link' do
    click_link 'Slack notifications'
  end

  step 'I fill Slack notifications settings' do
    check 'Active'
    fill_in 'Webhook', with: 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685'
    click_button 'Save'
  end

  step 'I should see the Slack notifications success message' do
    expect(page).to have_content 'Slack notifications activated.'
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

  step 'I should see the Pushover success message' do
    expect(page).to have_content 'Pushover activated.'
  end

  step 'I click jira service link' do
    click_link 'JIRA'
  end

  step 'I fill jira settings' do
    check 'Active'

    fill_in 'Web URL', with: 'http://jira.example'
    fill_in 'JIRA API URL', with: 'http://jira.example/api'
    fill_in 'Username', with: 'gitlab'
    fill_in 'Password', with: 'gitlab'
    fill_in 'Project Key', with: 'GITLAB'
    click_button 'Save'
  end

  step 'I should see the JIRA success message' do
    expect(page).to have_content 'JIRA activated.'
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

  step 'I should see the Bamboo success message' do
    expect(page).to have_content 'Atlassian Bamboo CI activated.'
  end

  step 'I should see empty field Change Password' do
    click_link 'Atlassian Bamboo CI'

    expect(find_field('Enter new password').value).to be_nil
  end

  step 'I click JetBrains TeamCity CI service link' do
    click_link 'JetBrains TeamCity CI'
  end

  step 'I fill JetBrains TeamCity CI settings' do
    check 'Active'
    fill_in 'Teamcity url', with: 'http://teamcity.example.com'
    fill_in 'Build type', with: 'GitlabTest_Build'
    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see the JetBrains success message' do
    expect(page).to have_content 'JetBrains TeamCity CI activated.'
  end
end
