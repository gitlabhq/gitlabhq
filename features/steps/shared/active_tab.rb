module SharedActiveTab
  include Spinach::DSL

  def ensure_active_main_tab(content)
    expect(find('.nav-sidebar > li.active')).to have_content(content)
  end

  def ensure_active_sub_tab(content)
    expect(find('div.content ul.center-top-menu li.active')).to have_content(content)
  end

  def ensure_active_sub_nav(content)
    expect(find('.sidebar-subnav > li.active')).to have_content(content)
  end

  step 'no other main tabs should be active' do
    expect(page).to have_selector('.nav-sidebar > li.active', count: 1)
  end

  step 'no other sub tabs should be active' do
    expect(page).to have_selector('div.content ul.center-top-menu li.active', count: 1)
  end

  step 'no other sub navs should be active' do
    expect(page).to have_selector('.sidebar-subnav > li.active', count: 1)
  end

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Projects')
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

  step 'the active main tab should be Help' do
    ensure_active_main_tab('Help')
  end
end
