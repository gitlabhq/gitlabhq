# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global search' do
  include AfterNextHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)

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

  it 'closes the dropdown on blur', :js do
    find('#search').click
    fill_in 'search', with: "a"

    expect(page).to have_selector("div[data-testid='dashboard-search-options'].show")

    find('#search').send_keys(:backspace)
    find('body').click

    expect(page).to have_no_selector("div[data-testid='dashboard-search-options'].show")
  end
end
