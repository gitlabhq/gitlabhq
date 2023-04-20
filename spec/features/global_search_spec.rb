# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global search', :js, feature_category: :global_search do
  include AfterNextHelpers

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

    it 'renders updated search bar' do
      expect(page).to have_no_selector('.search-form')
      expect(page).to have_selector('#js-header-search')
    end

    it 'focuses search input when shortcut "s" is pressed' do
      expect(page).not_to have_selector('#search:focus')

      find('body').native.send_key('s')

      expect(page).to have_selector('#search:focus')
    end
  end
end
