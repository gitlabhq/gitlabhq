module SharedActiveTab
  include Spinach::DSL
  include WaitForRequests

  after do
    wait_for_requests if javascript_test?
  end

  def ensure_active_main_tab(content)
    expect(find('.sidebar-top-level-items > li.active')).to have_content(content)
  end

  def ensure_active_sub_tab(content)
    expect(find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)')).to have_content(content)
  end

  def ensure_active_sub_nav(content)
    expect(find('.layout-nav .controls li.active')).to have_content(content)
  end

  step 'no other main tabs should be active' do
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
  end

  step 'no other sub tabs should be active' do
    expect(page).to have_selector('.sidebar-sub-level-items  > li.active:not(.fly-out-top-item)', count: 1)
  end

  step 'no other sub navs should be active' do
    expect(page).to have_selector('.layout-nav .controls li.active', count: 1)
  end
end
