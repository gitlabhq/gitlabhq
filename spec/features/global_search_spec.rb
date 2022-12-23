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

  describe 'when new_header_search feature is disabled' do
    before do
      # TODO: Remove this along with feature flag #339348
      stub_feature_flags(new_header_search: false)
      visit dashboard_projects_path
    end

    it 'increases usage ping searches counter' do
      expect(Gitlab::UsageDataCounters::SearchCounter).to receive(:count).with(:navbar_searches)
      expect(Gitlab::UsageDataCounters::SearchCounter).to receive(:count).with(:all_searches)

      submit_search('foobar')
    end

    describe 'I search through the issues and I see pagination' do
      before do
        allow_next(SearchService).to receive(:per_page).and_return(1)
        create_list(:issue, 2, project: project, title: 'initial')
      end

      it "has a pagination" do
        submit_search('initial')
        select_search_scope('Issues')

        expect(page).to have_selector('.gl-pagination .next')
      end
    end

    it 'closes the dropdown on blur' do
      find('#search').click
      fill_in 'search', with: "a"

      expect(page).to have_selector("div[data-testid='dashboard-search-options'].show")

      find('#search').send_keys(:backspace)
      find('body').click

      expect(page).to have_no_selector("div[data-testid='dashboard-search-options'].show")
    end

    it 'renders legacy search bar' do
      expect(page).to have_selector('.search-form')
      expect(page).to have_no_selector('#js-header-search')
    end

    it 'focuses search input when shortcut "s" is pressed' do
      expect(page).not_to have_selector('#search:focus')

      find('body').native.send_key('s')

      expect(page).to have_selector('#search:focus')
    end
  end

  describe 'when new_header_search feature is enabled' do
    before do
      # TODO: Remove this along with feature flag #339348
      stub_feature_flags(new_header_search: true)
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
