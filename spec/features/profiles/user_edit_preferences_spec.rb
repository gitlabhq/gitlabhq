# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edit preferences profile', :js, feature_category: :user_profile do
  include StubLanguagesTranslationPercentage

  # Empty value doesn't change the levels
  let(:language_percentage_levels) { nil }
  let(:user) { create(:user) }
  let(:vscode_web_ide) { true }

  before do
    stub_languages_translation_percentage(language_percentage_levels)
    stub_feature_flags(vscode_web_ide: vscode_web_ide)
    sign_in(user)
    visit(profile_preferences_path)
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

RSpec.describe 'Default text editor preference', :js, feature_category: :user_profile do
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
  end

  context 'when default text editor is disabled' do
    it 'is the default state' do
      expect(checkbox).not_to be_checked
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
