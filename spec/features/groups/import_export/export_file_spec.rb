# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Export', :js, feature_category: :importers do
  include ExportFileHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  context 'when the signed in user has the required permission level' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'allows the user to export the group', :sidekiq_inline do
      visit edit_group_path(group)

      expect(page).to have_content('Export group')

      click_link('Export group')
      expect(page).to have_content('Group export started')

      expect(page).to have_content('Download export')
    end
  end

  context 'when the signed in user does not have the required permission level' do
    before do
      group.add_guest(user)

      sign_in(user)
    end

    it 'does not let the user export the group' do
      visit edit_group_path(group)

      expect(page).to have_content('Page not found')
      expect(page).not_to have_content('Export group')
    end
  end
end
