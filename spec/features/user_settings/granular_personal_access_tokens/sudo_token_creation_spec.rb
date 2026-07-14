# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Granular personal access tokens > sudo capability',
  :with_current_organization, :js, feature_category: :system_access do
  include ListboxHelpers

  let_it_be(:admin) { create(:admin, :with_namespace) }
  let_it_be(:non_admin) { create(:user, :with_namespace) }

  before do
    stub_feature_flags(granular_personal_access_tokens: true)
  end

  context 'when the user is not an administrator' do
    before do
      sign_in(non_admin)
      visit granular_new_user_settings_personal_access_tokens_path
    end

    it 'does not show the sudo checkbox' do
      expect(page).to have_field('Name')
      expect(page).not_to have_selector('[data-testid="sudo-checkbox"]')
    end
  end

  context 'when the user is an administrator' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
      visit granular_new_user_settings_personal_access_tokens_path
    end

    it 'shows the sudo checkbox', :aggregate_failures do
      expect(page).to have_selector('[data-testid="sudo-checkbox"]')
      expect(page).to have_text('Use token to act on behalf of other users (sudo)')
    end

    it 'creates a token with the sudo capability enabled' do
      fill_in 'Name', with: 'Sudo PAT'
      fill_in 'Description', with: 'Token that can impersonate users'

      check 'Use token to act on behalf of other users (sudo)'

      choose 'All groups and projects that I\'m a member of'

      within_testid('resource-tree') do
        click_button 'Toggle Groups category'
        check 'Avatar'
      end

      within(find_by_testid('selected-resource', text: 'Avatar')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
      end

      click_on 'Generate token'

      expect(page).to have_text('Your new token has been created')
      expect(admin.personal_access_tokens.where(sudo: true).count).to eq(1)
    end
  end
end
