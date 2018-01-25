require 'spec_helper'

describe 'User visits the profile preferences page' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_preferences_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('Preferences')
  end

  describe 'User changes their syntax highlighting theme', :js do
    it 'creates a flash message' do
      choose 'user_color_scheme_id_5'

      wait_for_requests

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      choose 'user_color_scheme_id_5'

      wait_for_requests
      refresh

      expect(page).to have_checked_field('user_color_scheme_id_5')
    end
  end

  describe 'User changes their default dashboard', :js do
    it 'creates a flash message' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      wait_for_requests

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      wait_for_requests

      find('#logo').click

      expect(page).to have_content("You don't have starred projects yet")
      expect(page.current_path).to eq starred_dashboard_projects_path

      find('.shortcuts-activity').click

      expect(page).not_to have_content("You don't have starred projects yet")
      expect(page.current_path).to eq dashboard_projects_path
    end
  end

  def expect_preferences_saved_message
    page.within('.flash-container') do
      expect(page).to have_content('Preferences saved.')
    end
  end
end
