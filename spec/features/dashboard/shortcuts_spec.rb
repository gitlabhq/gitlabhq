require 'spec_helper'

feature 'Dashboard shortcuts', feature: true, js: true do
  context 'logged in' do
    before do
      login_as :user
      visit root_dashboard_path
    end

    scenario 'Navigate to tabs' do
      find('body').native.send_keys([:shift, 'P'])

      check_page_title('Projects')

      find('body').native.send_key([:shift, 'I'])

      check_page_title('Issues')

      find('body').native.send_key([:shift, 'M'])

      check_page_title('Merge Requests')

      find('body').native.send_keys([:shift, 'T'])

      check_page_title('Todos')
    end
  end

  context 'logged out' do
    before do
      visit explore_root_path
    end

    scenario 'Navigate to tabs' do
      find('body').native.send_keys([:shift, 'P'])

      expect(page).to have_content('No projects found')

      find('body').native.send_keys([:shift, 'G'])

      expect(page).to have_content('No public groups')

      find('body').native.send_keys([:shift, 'S'])

      expect(page).to have_selector('.snippets-list-holder')
    end
  end

  def check_page_title(title)
    expect(find('.header-content .title')).to have_content(title)
  end
end
