# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches their settings', :js do
  let(:user) { create(:user) }
  let(:search_input_placeholder) { 'Search settings' }

  before do
    sign_in(user)
  end

  context 'when search_settings_in_page feature flag is on' do
    it 'allows searching in the user profile page' do
      search_term = 'Public Avatar'
      hidden_section_name = 'Main settings'

      visit profile_path
      fill_in search_input_placeholder, with: search_term

      expect(page).to have_content(search_term)
      expect(page).not_to have_content(hidden_section_name)
    end

    it 'allows searching in the user applications page' do
      visit applications_profile_path

      expect(page.find_field(placeholder: search_input_placeholder)).not_to be_disabled
    end

    it 'allows searching in the user preferences page' do
      search_term = 'Syntax highlighting theme'
      hidden_section_name = 'Behavior'

      visit profile_preferences_path
      fill_in search_input_placeholder, with: search_term

      expect(page).to have_content(search_term)
      expect(page).not_to have_content(hidden_section_name)
    end
  end

  context 'when search_settings_in_page feature flag is off' do
    before do
      stub_feature_flags(search_settings_in_page: false)
      visit(profile_path)
    end

    it 'does not allow searching in the user settings pages' do
      expect(page).not_to have_content(search_input_placeholder)
    end
  end
end
