module SharedSidebarActiveTab
  include Spinach::DSL

  step 'no other main tabs should be active' do
    expect(page).to have_selector('.nav-sidebar li.active', count: 1)
  end

  def ensure_active_main_tab(content)
    expect(find('.nav-sidebar li.active')).to have_content(content)
  end

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Projects')
  end

  step 'the active main tab should be Groups' do
    ensure_active_main_tab('Groups')
  end

  step 'the active main tab should be Projects' do
    ensure_active_main_tab('Projects')
  end

  step 'the active main tab should be Issues' do
    ensure_active_main_tab('Issues')
  end

  step 'the active main tab should be Merge Requests' do
    ensure_active_main_tab('Merge Requests')
  end
end
