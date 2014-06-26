module SharedActiveTab
  include Spinach::DSL

  def ensure_active_main_tab(content)
    page.find('.main-nav li.active').should have_content(content)
  end

  def ensure_active_sub_tab(content)
    page.find('div.content ul.nav-tabs li.active').should have_content(content)
  end

  def ensure_active_sub_nav(content)
    page.find('div.content ul.nav-stacked-menu li.active').should have_content(content)
  end

  And 'no other main tabs should be active' do
    page.should have_selector('.main-nav li.active', count: 1)
  end

  And 'no other sub tabs should be active' do
    page.should have_selector('div.content ul.nav-tabs li.active', count: 1)
  end

  And 'no other sub navs should be active' do
    page.should have_selector('div.content ul.nav-stacked-menu li.active', count: 1)
  end
end
