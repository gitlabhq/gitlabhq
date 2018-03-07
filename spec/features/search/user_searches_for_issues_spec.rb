require 'spec_helper'

describe 'User searches for issues', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue1) { create(:issue, title: 'Foo', project: project) }
  let!(:issue2) { create(:issue, title: 'Bar', project: project) }

  context 'when signed in' do
    before do
      project.add_master(user)
      sign_in(user)

      visit(search_path)
    end

    include_examples 'top right search form'

    it 'finds an issue' do
      fill_in('dashboard_search', with: issue1.title)
      find('.btn-search').click

      page.within('.search-filter') do
        click_link('Issues')
      end

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_link(issue1.title).and have_no_link(issue2.title)
      end
    end

    context 'when on a project page' do
      it 'finds an issue' do
        find('.js-search-project-dropdown').click

        page.within('.project-filter') do
          click_link(project.full_name)
        end

        fill_in('dashboard_search', with: issue1.title)
        find('.btn-search').click

        page.within('.search-filter') do
          click_link('Issues')
        end

        page.within('.results') do
          expect(find(:css, '.search-results')).to have_link(issue1.title).and have_no_link(issue2.title)
        end
      end
    end
  end

  context 'when signed out' do
    let(:project) { create(:project, :public) }

    before do
      visit(search_path)
    end

    include_examples 'top right search form'

    it 'finds an issue' do
      fill_in('dashboard_search', with: issue1.title)
      find('.btn-search').click

      page.within('.search-filter') do
        click_link('Issues')
      end

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_link(issue1.title).and have_no_link(issue2.title)
      end
    end
  end
end
