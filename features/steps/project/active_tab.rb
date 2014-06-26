class ProjectActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedActiveTab

  # Main Tabs

  Then 'the active main tab should be Home' do
    ensure_active_main_tab('Activity')
  end

  Then 'the active main tab should be Settings' do
    ensure_active_main_tab('Settings')
  end

  Then 'the active main tab should be Files' do
    ensure_active_main_tab('Files')
  end

  Then 'the active main tab should be Commits' do
    ensure_active_main_tab('Commits')
  end

  Then 'the active main tab should be Network' do
    ensure_active_main_tab('Network')
  end

  Then 'the active main tab should be Issues' do
    ensure_active_main_tab('Issues')
  end

  Then 'the active main tab should be Merge Requests' do
    ensure_active_main_tab('Merge Requests')
  end

  Then 'the active main tab should be Wall' do
    ensure_active_main_tab('Wall')
  end

  Then 'the active main tab should be Wiki' do
    ensure_active_main_tab('Wiki')
  end

  # Sub Tabs: Home

  Given 'I click the "Team" tab' do
    click_link('Members')
  end

  Given 'I click the "Attachments" tab' do
    click_link('Attachments')
  end

  Given 'I click the "Snippets" tab' do
    click_link('Snippets')
  end

  Given 'I click the "Edit" tab' do
    within '.project-settings-nav' do
      click_link('Project')
    end
  end

  Given 'I click the "Hooks" tab' do
    click_link('Web Hooks')
  end

  Given 'I click the "Deploy Keys" tab' do
    click_link('Deploy Keys')
  end

  Then 'the active sub nav should be Team' do
    ensure_active_sub_nav('Members')
  end

  Then 'the active sub nav should be Edit' do
    ensure_active_sub_nav('Project')
  end

  Then 'the active sub nav should be Hooks' do
    ensure_active_sub_nav('Web Hooks')
  end

  Then 'the active sub nav should be Deploy Keys' do
    ensure_active_sub_nav('Deploy Keys')
  end

  # Sub Tabs: Commits

  Given 'I click the "Compare" tab' do
    click_link('Compare')
  end

  Given 'I click the "Branches" tab' do
    click_link('Branches')
  end

  Given 'I click the "Tags" tab' do
    click_link('Tags')
  end

  Then 'the active sub tab should be Commits' do
    ensure_active_sub_tab('Commits')
  end

  Then 'the active sub tab should be Compare' do
    ensure_active_sub_tab('Compare')
  end

  Then 'the active sub tab should be Branches' do
    ensure_active_sub_tab('Branches')
  end

  Then 'the active sub tab should be Tags' do
    ensure_active_sub_tab('Tags')
  end

  # Sub Tabs: Issues

  Given 'I click the "Milestones" tab' do
    click_link('Milestones')
  end

  Given 'I click the "Labels" tab' do
    click_link('Labels')
  end

  Then 'the active sub tab should be Browse Issues' do
    ensure_active_sub_tab('Browse Issues')
  end

  Then 'the active sub tab should be Milestones' do
    ensure_active_sub_tab('Milestones')
  end

  Then 'the active sub tab should be Labels' do
    ensure_active_sub_tab('Labels')
  end
end
