module SharedProjectTab
  include Spinach::DSL
  include SharedActiveTab

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Activity')
  end

  step 'the active main tab should be Files' do
    ensure_active_main_tab('Files')
  end

  step 'the active main tab should be Commits' do
    ensure_active_main_tab('Commits')
  end

  step 'the active main tab should be Network' do
    ensure_active_main_tab('Network')
  end

  step 'the active main tab should be Graphs' do
    ensure_active_main_tab('Graphs')
  end

  step 'the active main tab should be Issues' do
    ensure_active_main_tab('Issues')
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
    ensure_active_main_tab('Settings')
  end
end
