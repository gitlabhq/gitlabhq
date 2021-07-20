# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for merge requests', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:merge_request1) { create(:merge_request, title: 'Merge Request Foo', source_project: project, target_project: project, created_at: 1.hour.ago) }
  let!(:merge_request2) { create(:merge_request, :simple, title: 'Merge Request Bar', source_project: project, target_project: project) }

  def search_for_mr(search)
    fill_in('dashboard_search', with: search)
    find('.btn-search').click
    select_search_scope('Merge requests')
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'
  include_examples 'search timeouts', 'merge_requests'

  it 'finds a merge request' do
    search_for_mr(merge_request1.title)

    page.within('.results') do
      expect(page).to have_link(merge_request1.title)
      expect(page).not_to have_link(merge_request2.title)

      # Each result should have MR refs like `gitlab-org/gitlab!1`
      page.all('.search-result-row').each do |e|
        expect(e.text).to match(/!\d+/)
      end
    end
  end

  it 'sorts by created date' do
    search_for_mr('Merge Request')

    page.within('.results') do
      expect(page.all('.search-result-row').first).to have_link(merge_request2.title)
      expect(page.all('.search-result-row').last).to have_link(merge_request1.title)
    end

    find('[data-testid="sort-highest-icon"]').click

    page.within('.results') do
      expect(page.all('.search-result-row').first).to have_link(merge_request1.title)
      expect(page.all('.search-result-row').last).to have_link(merge_request2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a merge request' do
      find('[data-testid="project-filter"]').click

      wait_for_requests

      page.within('[data-testid="project-filter"]') do
        click_on(project.name)
      end

      search_for_mr(merge_request1.title)

      page.within('.results') do
        expect(page).to have_link(merge_request1.title)
        expect(page).not_to have_link(merge_request2.title)
      end
    end
  end
end
