require 'spec_helper'

feature 'Dashboard shortcuts', feature: true, js: true do
  before do
    login_as :user
    visit dashboard_projects_path
  end

  scenario 'Navigate to tabs' do
    find('body').native.send_key('g')
    find('body').native.send_key('p')

    ensure_active_main_tab('Projects')

    find('body').native.send_key('g')
    find('body').native.send_key('i')

    ensure_active_main_tab('Issues')

    find('body').native.send_key('g')
    find('body').native.send_key('m')

    ensure_active_main_tab('Merge Requests')
  end

  def ensure_active_main_tab(content)
    expect(find('.nav-sidebar li.active')).to have_content(content)
  end
end
