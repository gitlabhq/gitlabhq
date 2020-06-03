# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for issues', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue1) { create(:issue, title: 'Foo', project: project) }
  let!(:issue2) { create(:issue, title: 'Bar', project: project) }

  context 'when signed in' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(search_path)
    end

    include_examples 'top right search form'

    it 'finds an issue' do
      fill_in('dashboard_search', with: issue1.title)
      find('.btn-search').click
      select_search_scope('Issues')

      page.within('.results') do
        expect(page).to have_link(issue1.title)
        expect(page).not_to have_link(issue2.title)
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
        select_search_scope('Issues')

        page.within('.results') do
          expect(page).to have_link(issue1.title)
          expect(page).not_to have_link(issue2.title)
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
      select_search_scope('Issues')

      page.within('.results') do
        expect(page).to have_link(issue1.title)
        expect(page).not_to have_link(issue2.title)
      end
    end
  end
end
