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
    page.within '.sub-nav' do
      click_link('Edit Project')
    end
  end

  step 'I click the "Integrations" tab' do
    page.within '.sub-nav' do
      click_link('Integrations')
    end
  end

  step 'I click the "Repository" tab' do
    page.within '.sub-nav' do
      click_link('Repository')
    end
  end

  step 'I click the "Activity" tab' do
    page.within '.sub-nav' do
      click_link('Activity')
    end
  end

  step 'the active sub tab should be Members' do
    ensure_active_sub_tab('Members')
  end

  step 'the active sub tab should be Integrations' do
    ensure_active_sub_tab('Integrations')
  end

  step 'the active sub tab should be Repository' do
    ensure_active_sub_tab('Repository')
  end

  step 'the active sub tab should be Pages' do
    ensure_active_sub_tab('Pages')
  end

  step 'the active sub tab should be Activity' do
    ensure_active_sub_tab('Activity')
  end

  # Sub Tabs: Commits

  step 'I click the "Compare" tab' do
    click_link('Compare')
  end

  step 'I click the "Branches" tab' do
    page.within '.sub-nav' do
      click_link('Branches')
    end
  end

  step 'I click the "Tags" tab' do
    click_link('Tags')
  end

  step 'I click the "Charts" tab' do
    page.within '.sub-nav' do
      click_link('Charts')
    end
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
