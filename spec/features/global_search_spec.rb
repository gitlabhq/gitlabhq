# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global search', :js, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
  let_it_be(:search_selector) { 'input[type="search"]:focus' }

  before do
    project.add_maintainer(user)
  end

  after do
    expect_page_to_have_no_console_errors
  end

  shared_examples 'header search' do
    it 'renders search button' do
      expect(page).to have_button('Search or go to…')
    end

    it 'opens search modal when shortcut "s" is pressed' do
      expect(page).not_to have_selector(search_selector)

      find('body').native.send_key('s')

      expect(page).to have_selector(search_selector)

      wait_for_requests
    end
  end

  describe 'when signed out' do
    before do
      visit project_path(project)
    end

    it_behaves_like 'header search'
  end

  describe 'when signed in' do
    before do
      sign_in(user)

      visit dashboard_projects_path
    end

    it_behaves_like 'header search'
  end
end
