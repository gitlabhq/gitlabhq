require 'spec_helper'

feature 'Dashboard shortcuts', feature: true, js: true do
  before do
    login_as :user
    visit dashboard_projects_path
  end

  scenario 'Navigate to tabs' do
    find('body').native.send_key('g')
    find('body').native.send_key('p')

    check_page_title('Projects')

    find('body').native.send_key('g')
    find('body').native.send_key('i')

    check_page_title('Issues')

    find('body').native.send_key('g')
    find('body').native.send_key('m')

    check_page_title('Merge Requests')
  end

  def check_page_title(title)
    expect(find('.header-content .title')).to have_content(title)
  end
end
