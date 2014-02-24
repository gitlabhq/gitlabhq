class ProjectServices < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I visit project "Shop" services page' do
    visit project_services_path(@project)
  end

  step 'I should see list of available services' do
    page.should have_content 'Project services'
    page.should have_content 'Campfire'
    page.should have_content 'Hipchat'
    page.should have_content 'GitLab CI'
    page.should have_content 'Assembla'
    page.should have_content 'Gemnasium'
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
    find_field('Project url').value.should == 'http://ci.gitlab.org/projects/3'
  end

  step 'I click hipchat service link' do
    click_link 'Hipchat'
  end

  step 'I fill hipchat settings' do
    check 'Active'
    fill_in 'Room', with: 'gitlab'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see hipchat service settings saved' do
    find_field('Room').value.should == 'gitlab'
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
    find_field('Token').value.should == 'verySecret'
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
    find_field('Token').value.should == 'verySecret'
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
    find_field('Token').value.should == 'verySecret'
  end

  step 'I click email on push service link' do
    click_link 'Emails on push'
  end

  step 'I fill email on push settings' do
    fill_in 'Recipients', with: 'qa@company.name'
    click_button 'Save'
  end

  step 'I should see email on push service settings saved' do
    find_field('Recipients').value.should == 'qa@company.name'
  end

  step 'I click Gemnasium service link' do
    click_link 'Gemnasium'
  end

  step 'I fill Gemnasium settings' do
    check 'Active'
    fill_in 'Api key', with: 'verySecretApiKey'
    fill_in 'Token', with: 'verySecret'
    click_button 'Save'
  end

  step 'I should see Gemnasium service settings saved' do
    find_field('Api key').value.should == 'verySecretApiKey'
    find_field('Token').value.should == 'verySecret'
  end

  step 'I should see Gemnasium service help text' do
    page.should have_content "To setup the service you'll need to register an account on gemnasium.com and add your project."
  end

end
