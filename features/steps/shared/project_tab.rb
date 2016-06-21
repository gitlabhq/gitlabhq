require_relative 'active_tab'

module SharedProjectTab
  include Spinach::DSL
  include SharedActiveTab

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Project')
  end

  step 'the active main tab should be Repository' do
    ensure_active_main_tab('Repository')
  end

  step 'the active main tab should be Graphs' do
    ensure_active_main_tab('Graphs')
  end

  step 'the active main tab should be Issues' do
    ensure_active_main_tab('Issues')
  end

  step 'the active main tab should be Members' do
    ensure_active_main_tab('Members')
  end

  step 'the active main tab should be Merge Requests' do
    ensure_active_main_tab('Merge Requests')
  end

  step 'the active main tab should be Snippets' do
    ensure_active_main_tab('Snippets')
  end

  step 'the active main tab should be Wiki' do
    ensure_active_main_tab('Wiki')
  end

  step 'the active main tab should be Settings' do
    expect(page).to have_selector('.layout-nav .nav-links > li.active', count: 0)
  end

  step 'the active main tab should be Activity' do
    ensure_active_main_tab('Activity')
  end

  step 'the active sub tab should be Network' do
    ensure_active_sub_tab('Network')
  end

  step 'the active sub tab should be Files' do
    ensure_active_sub_tab('Files')
  end

  step 'the active sub tab should be Commits' do
    ensure_active_sub_tab('Commits')
  end
end
