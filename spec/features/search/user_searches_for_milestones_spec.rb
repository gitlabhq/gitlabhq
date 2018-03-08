require 'spec_helper'

describe 'User searches for milestones', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:milestone1) { create(:milestone, title: 'Foo', project: project) }
  let!(:milestone2) { create(:milestone, title: 'Bar', project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'

  it 'finds a milestone' do
    fill_in('dashboard_search', with: milestone1.title)
    find('.btn-search').click

    page.within('.search-filter') do
      click_link('Milestones')
    end

    page.within('.results') do
      expect(find(:css, '.search-results')).to have_link(milestone1.title).and have_no_link(milestone2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a milestone' do
      find('.js-search-project-dropdown').click

      page.within('.project-filter') do
        click_link(project.full_name)
      end

      fill_in('dashboard_search', with: milestone1.title)
      find('.btn-search').click

      page.within('.search-filter') do
        click_link('Milestones')
      end

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_link(milestone1.title).and have_no_link(milestone2.title)
      end
    end
  end
end
