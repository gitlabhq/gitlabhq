require 'spec_helper'

describe 'Profile > Preferences', feature: true do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit profile_preferences_path
  end

  describe 'User changes their syntax highlighting theme', js: true do
    it 'creates a flash message' do
      choose 'user_color_scheme_id_5'

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      choose 'user_color_scheme_id_5'

      allowing_for_delay do
        visit page.current_path
        expect(page).to have_checked_field('user_color_scheme_id_5')
      end
    end
  end

  describe 'User changes their default dashboard', js: true do
    it 'creates a flash message' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      allowing_for_delay do
        find('#logo').click

        expect(page).to have_content("You don't have starred projects yet")
        expect(page.current_path).to eq starred_dashboard_projects_path
      end

      find('.shortcuts-activity').trigger('click')

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
