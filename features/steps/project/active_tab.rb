class Spinach::Features::ProjectActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedActiveTab
  include SharedProjectTab

  # Sub Tabs: Home

  step 'I click the "Team" tab' do
    click_link('Members')
  end

  step 'I click the "Attachments" tab' do
    click_link('Attachments')
  end

  step 'I click the "Snippets" tab' do
    click_link('Snippets')
  end

  step 'I click the "Edit" tab' do
    page.within '.sidebar-subnav' do
      click_link('Project Settings')
    end
  end

  step 'I click the "Hooks" tab' do
    click_link('Webhooks')
  end

  step 'I click the "Deploy Keys" tab' do
    click_link('Deploy Keys')
  end

  step 'the active sub nav should be Team' do
    ensure_active_sub_nav('Members')
  end

  step 'the active sub nav should be Edit' do
    ensure_active_sub_nav('Project')
  end

  step 'the active sub nav should be Hooks' do
    ensure_active_sub_nav('Webhooks')
  end

  step 'the active sub nav should be Deploy Keys' do
    ensure_active_sub_nav('Deploy Keys')
  end

  # Sub Tabs: Commits

  step 'I click the "Compare" tab' do
    click_link('Compare')
  end

  step 'I click the "Branches" tab' do
    click_link('Branches')
  end

  step 'I click the "Tags" tab' do
    click_link('Tags')
  end

  step 'the active sub tab should be Commits' do
    ensure_active_sub_tab('Commits')
  end

  step 'the active sub tab should be Compare' do
    ensure_active_sub_tab('Compare')
  end

  step 'the active sub tab should be Branches' do
    ensure_active_sub_tab('Branches')
  end

  step 'the active sub tab should be Tags' do
    ensure_active_sub_tab('Tags')
  end

  # Sub Tabs: Issues

  step 'I click the "Milestones" tab' do
    click_link('Milestones')
  end

  step 'I click the "Labels" tab' do
    click_link('Labels')
  end

  step 'the active sub tab should be Issues' do
    ensure_active_sub_tab('Issues')
  end

  step 'the active main tab should be Milestones' do
    ensure_active_main_tab('Milestones')
  end

  step 'the active main tab should be Labels' do
    ensure_active_main_tab('Labels')
  end
end
