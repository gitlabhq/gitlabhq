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
    page.within('.layout-nav') do
      click_link('Snippets')
    end
  end

  step 'I click the "Edit Project"' do
    page.within '.layout-nav .controls' do
      click_link('Edit Project')
    end
  end

  step 'I click the "Hooks" tab' do
    click_link('Webhooks')
  end

  step 'I click the "Deploy Keys" tab' do
    click_link('Deploy Keys')
  end

  step 'I click the "Pages" tab' do
    click_link('Pages')
  end

  step 'the active sub nav should be Members' do
    ensure_active_sub_nav('Members')
  end

  step 'the active sub nav should be Hooks' do
    ensure_active_sub_nav('Webhooks')
  end

  step 'the active sub nav should be Deploy Keys' do
    ensure_active_sub_nav('Deploy Keys')
  end

  step 'the active sub nav should be Pages' do
    ensure_active_sub_nav('Pages')
  end

  # Sub Tabs: Commits

  step 'I click the "Compare" tab' do
    click_link('Compare')
  end

  step 'I click the "Branches" tab' do
    page.within '.content' do
      click_link('Branches')
    end
  end

  step 'I click the "Tags" tab' do
    click_link('Tags')
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

  step 'I click the "Milestones" sub tab' do
    page.within('.sub-nav') do
      click_link('Milestones')
    end
  end

  step 'I click the "Labels" sub tab' do
    page.within('.sub-nav') do
      click_link('Labels')
    end
  end

  step 'the active sub tab should be Issues' do
    ensure_active_sub_tab('Issues')
  end

  step 'the active sub tab should be Milestones' do
    ensure_active_sub_tab('Milestones')
  end

  step 'the active sub tab should be Labels' do
    ensure_active_sub_tab('Labels')
  end
end
