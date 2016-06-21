module SharedActiveTab
  include Spinach::DSL

  def ensure_active_main_tab(content)
    expect(find('.layout-nav li.active')).to have_content(content)
  end

  def ensure_active_sub_tab(content)
    expect(find('.sub-nav li.active')).to have_content(content)
  end

  def ensure_active_sub_nav(content)
    expect(find('.layout-nav .controls li.active')).to have_content(content)
  end

  step 'no other main tabs should be active' do
    expect(page).to have_selector('.layout-nav .nav-links > li.active', count: 1)
  end

  step 'no other sub tabs should be active' do
    expect(page).to have_selector('.sub-nav li.active', count: 1)
  end

  step 'no other sub navs should be active' do
    expect(page).to have_selector('.layout-nav .controls li.active', count: 1)
  end
end
