require 'spec_helper'

describe 'User searches for merge requests', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:merge_request1) { create(:merge_request, title: 'Foo', source_project: project, target_project: project) }
  let!(:merge_request2) { create(:merge_request, :simple, title: 'Bar', source_project: project, target_project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'

  it 'finds a merge request' do
    fill_in('dashboard_search', with: merge_request1.title)
    find('.btn-search').click

    page.within('.search-filter') do
      click_link('Merge requests')
    end

    page.within('.results') do
      expect(find(:css, '.search-results')).to have_link(merge_request1.title).and have_no_link(merge_request2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a merge request' do
      find('.js-search-project-dropdown').click

      page.within('.project-filter') do
        click_link(project.full_name)
      end

      fill_in('dashboard_search', with: merge_request1.title)
      find('.btn-search').click

      page.within('.search-filter') do
        click_link('Merge requests')
      end

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_link(merge_request1.title).and have_no_link(merge_request2.title)
      end
    end
  end
end
