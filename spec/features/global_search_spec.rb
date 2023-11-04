# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global search', :js, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'when header search' do
    before do
      visit dashboard_projects_path
    end

    it 'renders search button' do
      expect(page).to have_button('Search or go to…')
    end

    it 'opens search modal when shortcut "s" is pressed' do
      search_selector = 'input[type="search"]:focus'

      expect(page).not_to have_selector(search_selector)

      find('body').native.send_key('s')

      expect(page).to have_selector(search_selector)
    end
  end
end
