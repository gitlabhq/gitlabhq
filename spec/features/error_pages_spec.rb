# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Error Pages', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    sign_in(user)
  end

  shared_examples 'shows nav links' do
    it 'shows nav links' do
      expect(page).to have_link("Home", href: root_path)
      expect(page).to have_link("Help", href: help_path)
    end

    it 'allows user to sign out' do
      click_link 'Sign out and sign in with a different account'

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe '404' do
    before do
      visit '/not-a-real-page'
    end

    it 'allows user to search' do
      fill_in 'search', with: 'something'
      click_button 'Search'

      expect(page).to have_current_path(%r{^/search\?.*search=something.*})
    end

    it_behaves_like 'shows nav links'
  end

  describe '403' do
    before do
      visit '/'
      visit edit_project_path(project)
    end

    it_behaves_like 'shows nav links'
  end
end
