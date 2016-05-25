class Spinach::Features::AdminActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSidebarActiveTab

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Overview')
  end

  step 'the active main tab should be Projects' do
    ensure_active_main_tab('Projects')
  end

  step 'the active main tab should be Groups' do
    ensure_active_main_tab('Groups')
  end

  step 'the active main tab should be Users' do
    ensure_active_main_tab('Users')
  end

  step 'the active main tab should be Logs' do
    ensure_active_main_tab('Logs')
  end

  step 'the active main tab should be Hooks' do
    ensure_active_main_tab('Hooks')
  end

  step 'the active main tab should be Resque' do
    ensure_active_main_tab('Background Jobs')
  end

  step 'the active main tab should be Messages' do
    ensure_active_main_tab('Messages')
  end

  step 'no other main tabs should be active' do
    expect(page).to have_selector('.nav-sidebar > li.active', count: 1)
  end

  def ensure_active_main_tab(content)
    expect(find('.nav-sidebar > li.active')).to have_content(content)
  end
end
