require 'spec_helper'

describe 'Profile > Preferences' do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'User changes their application theme', js: true do
    let(:default_class) { Gitlab::Theme.css_class_by_id(nil) }
    let(:theme_5_class) { Gitlab::Theme.css_class_by_id(5) }

    before do
      visit profile_preferences_path
    end

    it 'creates a flash message' do
      choose "user_theme_id_#{theme.id}"

      within('.flash-container') do
        expect(page).to have_content('Preferences saved.')
      end
    end

    it 'reflects the changes immediately' do
      expect(page).to have_selector("body.#{default.css_class}")

      choose "user_theme_id_#{theme.id}"

      expect(page).not_to have_selector("body.#{default.css_class}")
      expect(page).to have_selector("body.#{theme.css_class}")
    end
  end

  describe 'User changes their syntax highlighting theme' do
    before do
      visit profile_preferences_path
    end
  end
end
