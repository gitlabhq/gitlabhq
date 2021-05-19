# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edit preferences profile', :js do
  include StubLanguagesTranslationPercentage

  # Empty value doesn't change the levels
  let(:language_percentage_levels) { nil }
  let(:user) { create(:user) }

  before do
    stub_languages_translation_percentage(language_percentage_levels)
    stub_feature_flags(user_time_settings: true)
    sign_in(user)
    visit(profile_preferences_path)
  end

  it 'allows the user to toggle their time format preference' do
    field = page.find_field("user[time_format_in_24h]")

    expect(field).not_to be_checked

    field.click

    expect(field).to be_checked
  end

  it 'allows the user to toggle their time display preference' do
    field = page.find_field("user[time_display_relative]")

    expect(field).to be_checked

    field.click

    expect(field).not_to be_checked
  end

  describe 'User changes tab width to acceptable value' do
    it 'shows success message' do
      fill_in 'Tab width', with: 9
      click_button 'Save changes'

      expect(page).to have_content('Preferences saved.')
    end

    it 'saves the value' do
      tab_width_field = page.find_field('Tab width')

      expect do
        tab_width_field.fill_in with: 6
        click_button 'Save changes'
      end.to change { tab_width_field.value }
    end
  end

  describe 'User changes tab width to unacceptable value' do
    it 'shows error message' do
      fill_in 'Tab width', with: -1
      click_button 'Save changes'

      field = page.find_field('user[tab_width]')
      message = field.native.attribute("validationMessage")
      expect(message).to eq "Value must be greater than or equal to 1."

      # User trying to hack an invalid value
      page.execute_script("document.querySelector('#user_tab_width').setAttribute('min', '-1')")
      click_button 'Save changes'
      expect(page).to have_content('Failed to save preferences.')
    end
  end
end
