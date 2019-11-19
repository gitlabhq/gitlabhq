# frozen_string_literal: true

require 'spec_helper'

describe 'Global search' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit dashboard_projects_path
  end

  it 'increases usage ping searches counter' do
    expect(Gitlab::UsageDataCounters::SearchCounter).to receive(:increment_navbar_searches_count)

    submit_search('foobar')
  end

  describe 'I search through the issues and I see pagination' do
    before do
      allow_next_instance_of(Gitlab::SearchResults) do |instance|
        allow(instance).to receive(:per_page).and_return(1)
      end
      create_list(:issue, 2, project: project, title: 'initial')
    end

    it "has a pagination" do
      submit_search('initial')
      select_search_scope('Issues')

      expect(page).to have_selector('.gl-pagination .next')
    end
  end

  it 'closes the dropdown on blur', :js do
    fill_in 'search', with: "a"
    dropdown = find('.js-dashboard-search-options')

    expect(dropdown[:class]).to include 'show'

    find('#search').send_keys(:backspace)
    find('body').click

    expect(dropdown[:class]).not_to include 'show'
  end
end
