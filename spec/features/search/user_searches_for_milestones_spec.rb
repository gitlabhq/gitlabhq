# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for milestones', :js, :clean_gitlab_redis_rate_limiting,
  feature_category: :global_search do
  include ListboxHelpers
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:milestone1) { create(:milestone, title: 'Foo', project: project) }
  let_it_be(:milestone2) { create(:milestone, title: 'Bar', project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'
  include_examples 'search timeouts', 'milestones'

  it 'shows scopes when there is no search term' do
    submit_dashboard_search('')

    within_testid('search-filter') do
      expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
    end
  end

  it 'finds a milestone' do
    submit_dashboard_search(milestone1.title)
    select_search_scope('Milestones')

    page.within('.results') do
      expect(page).to have_link(milestone1.title)
      expect(page).not_to have_link(milestone2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a milestone' do
      find_by_testid('project-filter').click

      wait_for_requests

      within_testid('project-filter') do
        select_listbox_item project.name
      end

      submit_dashboard_search(milestone1.title)
      select_search_scope('Milestones')

      page.within('.results') do
        expect(page).to have_link(milestone1.title)
        expect(page).not_to have_link(milestone2.title)
      end
    end
  end
end
