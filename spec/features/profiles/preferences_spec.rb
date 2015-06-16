require 'spec_helper'

describe 'Profile > Preferences' do
  before do
    login_as(:user)
    visit profile_preferences_path
  end

  describe 'User changes their application theme', js: true do
    let(:default_class) { Gitlab::Theme.css_class_by_id(nil) }
    let(:theme_5_class) { Gitlab::Theme.css_class_by_id(5) }

    it 'creates a flash message' do
      choose 'user_theme_id_5'

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      choose 'user_theme_id_5'

      allowing_for_delay do
        visit page.current_path
        expect(page).to have_checked_field("user_theme_id_5")
      end
    end

    it 'reflects the changes immediately' do
      expect(page).to have_selector("body.#{default_class}")

      choose 'user_theme_id_5'

      expect(page).not_to have_selector("body.#{default_class}")
      expect(page).to have_selector("body.#{theme_5_class}")
    end
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

  describe 'User changes their default dashboard' do
    it 'creates a flash message' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      select 'Starred Projects', from: 'user_dashboard'
      click_button 'Save'

      click_link 'Dashboard'
      expect(page.current_path).to eq starred_dashboard_projects_path

      click_link 'Your Projects'
      expect(page.current_path).to eq dashboard_path
    end
  end

  def expect_preferences_saved_message
    within('.flash-container') do
      expect(page).to have_content('Preferences saved.')
    end
  end
end
