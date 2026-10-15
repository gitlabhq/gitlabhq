# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edit preferences profile', :js, feature_category: :user_profile do
  include StubLanguagesTranslationPercentage

  # Empty value doesn't change the levels
  let(:language_percentage_levels) { nil }
  let(:user) { create(:user) }

  before do
    stub_languages_translation_percentage(language_percentage_levels)
    sign_in(user)
    visit(profile_preferences_path)
  end

  it 'allows the user to toggle their time display preference' do
    click_link 'Localization'
    field = page.find_field("user[time_display_relative]")

    expect(field).to be_checked

    field.click

    expect(field).not_to be_checked
  end

  it 'allows the user to disable emoji autocomplete and persists the choice' do
    click_link 'Editing'
    field = page.find_field("user[emoji_autocomplete_enabled]")

    expect(field).to be_checked

    field.click
    click_button 'Save changes'

    expect(page).to have_content('Preferences saved.')
    expect(user.reload.user_preference.emoji_autocomplete_enabled).to be(false)

    visit(profile_preferences_path)
    click_link 'Editing'
    expect(page.find_field("user[emoji_autocomplete_enabled]")).not_to be_checked
  end

  describe 'User changes tab width to acceptable value' do
    before do
      click_link 'Editing'
    end

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
    before do
      click_link 'Editing'
    end

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

    it 'switches to the tab containing the invalid field when saving from another tab' do
      fill_in 'Tab width', with: -1
      click_link 'Appearance'

      expect(page).not_to have_field('Tab width')

      click_button 'Save changes'

      expect(page).to have_field('Tab width')
      expect(page).to have_css('a[role="tab"].active', text: 'Editing')
    end
  end

  describe 'Tabs' do
    it 'shows the appearance tab by default and switches tabs without reloading' do
      expect(page).to have_css('a[role="tab"].active', text: 'Appearance')
      expect(page).to have_content('Syntax highlighting')
      expect(page).not_to have_content('Time preferences')

      click_link 'Localization'

      expect(page).to have_css('a[role="tab"].active', text: 'Localization')
      expect(page).to have_content('Time preferences')
      expect(page).not_to have_content('Syntax highlighting')
      expect(current_url_hash).to eq('#localization')
    end

    # A hash-only `visit` from the same page does not reload it, so leave the page first.
    it 'opens the tab named by the URL hash on page load' do
      visit(user_settings_profile_path)
      visit(profile_preferences_path(anchor: 'editing'))

      expect(page).to have_css('a[role="tab"].active', text: 'Editing')
      expect(page).to have_field('Tab width')
    end

    it 'opens the tab containing a deep-linked field on page load and keeps the hash' do
      visit(user_settings_profile_path)
      visit(profile_preferences_path(anchor: 'user_tab_width'))

      expect(page).to have_css('a[role="tab"].active', text: 'Editing')
      expect(page).to have_field('Tab width')
      expect(current_url_hash).to eq('#user_tab_width')
    end

    it 'opens the tab containing a deep-linked Vue-rendered field' do
      stub_application_setting(gitpod_enabled: true, gitpod_url: 'https://gitpod.test')

      visit(user_settings_profile_path)
      visit(profile_preferences_path(anchor: 'user_gitpod_enabled'))

      expect(page).to have_css('a[role="tab"].active', text: 'Integrations')
      expect(page).to have_field('user[gitpod_enabled]', type: 'checkbox')
      expect(current_url_hash).to eq('#user_gitpod_enabled')
    end

    it 'follows hash changes made after the page has loaded' do
      page.execute_script("window.location.hash = '#localization'")

      expect(page).to have_css('a[role="tab"].active', text: 'Localization')

      page.execute_script("window.location.hash = '#user_tab_width'")

      expect(page).to have_css('a[role="tab"].active', text: 'Editing')
      expect(page).to have_field('Tab width')
    end

    context 'when the preferences_tabs feature flag is disabled' do
      before do
        stub_feature_flags(preferences_tabs: false)
        visit(profile_preferences_path)
      end

      it 'shows every section on one page and still saves' do
        expect(page).not_to have_css('a[role="tab"]')
        expect(page).to have_content('Syntax highlighting')
        expect(page).to have_content('Time preferences')

        fill_in 'Tab width', with: 9
        click_button 'Save changes'

        expect(page).to have_content('Preferences saved.')
        expect(user.reload.tab_width).to eq(9)
      end
    end
  end

  def current_url_hash
    page.evaluate_script('window.location.hash')
  end
end

RSpec.describe 'Default text editor preference', :js, :allow_rich_text_editor_for_new_users, feature_category: :user_profile do
  include RichTextEditorHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:checkbox) { page.find_field("user[default_text_editor_enabled]") }
  let(:radio_rich_text) { page.find('input[type="radio"][value="rich_text_editor"]') }
  let(:radio_plain_text) { page.find('input[type="radio"][value="plain_text_editor"]') }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
    visit(profile_preferences_path)
    click_link 'Editing'
  end

  context 'when default text editor is disabled' do
    before do
      checkbox.set(false)
      click_button 'Save changes'
    end

    it 'disables radio buttons' do
      expect(radio_rich_text).to be_disabled
      expect(radio_plain_text).to be_disabled
    end

    it 'shows plain text editor by default and persists rich text editor selection after refresh' do
      visit project_issue_path(project, issue)
      wait_for_requests

      expect(page).to have_css('textarea')
      expect(page).not_to have_css(content_editor_testid)

      switch_to_content_editor
      expect(page).to have_css(content_editor_testid)

      refresh
      expect(page).to have_css(content_editor_testid)
    end
  end

  context 'when default text editor is enabled' do
    before do
      checkbox.set(true)
    end

    it 'is the default state with rich text editor selected' do
      expect(checkbox).to be_checked
      expect(radio_rich_text).to be_checked
    end

    it 'enables radio buttons' do
      expect(radio_rich_text).not_to be_disabled
      expect(radio_plain_text).not_to be_disabled
    end

    context 'with rich text as default' do
      before do
        radio_rich_text.set(true)
        click_button 'Save changes'
      end

      it 'shows rich text editor by default and persists it after switching and refreshing' do
        visit project_issue_path(project, issue)
        wait_for_requests

        expect(page).to have_css(content_editor_testid)
        expect(page).not_to have_css('textarea')

        switch_to_markdown_editor
        expect(page).to have_css('textarea')

        refresh
        expect(page).to have_css(content_editor_testid)
        expect(page).not_to have_css('textarea')
      end
    end

    context 'with plain text as default' do
      before do
        radio_plain_text.set(true)
        click_button 'Save changes'
      end

      it 'shows plain text editor by default and persists it after switching and refreshing' do
        visit project_issue_path(project, issue)
        wait_for_requests

        expect(page).to have_css('textarea')
        expect(page).not_to have_css(content_editor_testid)

        switch_to_content_editor
        expect(page).to have_css(content_editor_testid)

        refresh
        expect(page).to have_css('textarea')
        expect(page).not_to have_css(content_editor_testid)
      end
    end
  end
end
