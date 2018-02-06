require 'spec_helper'

feature 'Dashboard shortcuts', :js do
  context 'logged in' do
    before do
      sign_in(create(:user))
      visit root_dashboard_path
    end

    scenario 'Navigate to tabs' do
      find('body').send_keys([:shift, 'I'])

      check_page_title('Issues')

      find('body').send_keys([:shift, 'M'])

      check_page_title('Merge Requests')

      find('body').send_keys([:shift, 'T'])

      check_page_title('Todos')

      find('body').send_keys([:shift, 'P'])

      check_page_title('Projects')
    end
  end

  context 'logged out' do
    before do
      visit explore_root_path
    end

    scenario 'Navigate to tabs' do
      find('body').send_keys([:shift, 'G'])

      find('.nothing-here-block')
      expect(page).to have_content('No public groups')

      find('body').send_keys([:shift, 'S'])

      find('.nothing-here-block')
      expect(page).to have_selector('.snippets-list-holder')

      find('body').send_keys([:shift, 'P'])

      find('.nothing-here-block')
      expect(page).to have_content('No projects found')
    end
  end

  def check_page_title(title)
    expect(find('.breadcrumbs-sub-title')).to have_content(title)
  end
end
