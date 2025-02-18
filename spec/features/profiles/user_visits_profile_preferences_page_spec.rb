# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the profile preferences page', :js, feature_category: :user_profile do
  include ListboxHelpers

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User changes their syntax highlighting theme', :js do
    before do
      visit(profile_preferences_path)
    end

    it 'updates their preference' do
      choose 'user_color_scheme_id_5'

      wait_for_requests
      refresh

      expect(page).to have_checked_field('user_color_scheme_id_5')
    end
  end

  context 'when your_work_projects_vue feature flag is enabled' do
    before do
      stub_feature_flags(your_work_projects_vue: true)
      visit(profile_preferences_path)
    end

    it 'sets default dashboard preference to Your Contributed Projects (default)' do
      expect(page).to have_button('Your Contributed Projects (default)')
    end
  end

  context 'when your_work_projects_vue feature flag is disabled' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
      visit(profile_preferences_path)
    end

    it 'sets default dashboard preference to Your Projects (default)' do
      expect(page).to have_button('Your Projects (default)')
    end
  end

  describe 'User changes their default dashboard', :js do
    context 'when feature flag your_work_projects_vue is enabled' do
      before do
        visit(profile_preferences_path)
      end

      it 'creates a flash message' do
        select_from_listbox 'Starred Projects', from: 'Your Contributed Projects (default)', exact_item_text: true
        click_button 'Save changes'

        wait_for_requests

        expect_preferences_saved_message
      end

      it 'updates their preference' do
        select_from_listbox 'Starred Projects', from: 'Your Contributed Projects (default)', exact_item_text: true
        click_button 'Save changes'

        wait_for_requests

        find('[data-track-label="gitlab_logo_link"]').click
        wait_for_requests

        expect(page).to have_content("You haven't starred any projects yet.")
        expect(page).to have_current_path starred_dashboard_projects_path, ignore_query: true
      end
    end

    context 'when feature flag your_work_projects_vue is disabled' do
      before do
        stub_feature_flags(your_work_projects_vue: false)
        visit(profile_preferences_path)
      end

      it 'creates a flash message' do
        select_from_listbox 'Starred Projects', from: 'Your Projects', exact_item_text: true
        click_button 'Save changes'

        wait_for_requests

        expect_preferences_saved_message
      end

      it 'updates their preference' do
        select_from_listbox 'Starred Projects', from: 'Your Projects', exact_item_text: true
        click_button 'Save changes'

        wait_for_requests

        find('[data-track-label="gitlab_logo_link"]').click

        expect(page).to have_content("You don't have starred projects yet")
        expect(page).to have_current_path starred_dashboard_projects_path, ignore_query: true

        find('.shortcuts-activity').click

        expect(page).not_to have_content("You don't have starred projects yet")
        expect(page).to have_current_path dashboard_projects_path, ignore_query: true
      end
    end
  end

  describe 'User changes their language', :js do
    before do
      visit(profile_preferences_path)
    end

    it 'creates a flash message' do
      select_from_listbox 'English', from: 'English'
      click_button 'Save changes'

      wait_for_requests

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      wait_for_requests
      select_from_listbox 'Portuguese', from: 'English'
      click_button 'Save changes'

      wait_for_requests
      refresh

      expect(page).to have_css('html[lang="pt-BR"]')
    end
  end

  describe 'User changes whitespace in code' do
    before do
      visit(profile_preferences_path)
    end

    it 'updates their preference' do
      expect(user.render_whitespace_in_code).to be(false)
      expect(render_whitespace_field).not_to be_checked
      render_whitespace_field.click

      click_button 'Save changes'

      wait_for_requests

      expect(user.reload.render_whitespace_in_code).to be(true)
      expect(render_whitespace_field).to be_checked
    end
  end

  def render_whitespace_field
    find_field('user[render_whitespace_in_code]')
  end

  def expect_preferences_saved_message
    page.within('.b-toaster') do
      expect(page).to have_content('Preferences saved.')
    end
  end
end
