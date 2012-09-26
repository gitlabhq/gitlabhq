module SharedActiveTab
  include Spinach::DSL

  def ensure_active_main_tab(content)
    page.find('ul.main_menu li.current').should have_content(content)
  end

  And 'no other main tabs should be active' do
    page.should have_selector('ul.main_menu li.current', count: 1)
  end
end
