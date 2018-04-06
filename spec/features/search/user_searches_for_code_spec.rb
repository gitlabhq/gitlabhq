require 'spec_helper'

describe 'User searches for code' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'when signed in' do
    before do
      project.add_master(user)
      sign_in(user)
    end

    it 'finds a file' do
      visit(project_path(project))

      page.within('.search') do
        fill_in('search', with: 'application.js')
        click_button('Go')
      end

      click_link('Code')

      expect(page).to have_selector('.file-content .code')
      expect(page).to have_selector("span.line[lang='javascript']")
    end

    context 'when on a project page', :js do
      before do
        visit(search_path)
      end

      include_examples 'top right search form'

      it 'finds code' do
        find('.js-search-project-dropdown').click

        page.within('.project-filter') do
          click_link(project.full_name)
        end

        fill_in('dashboard_search', with: 'rspec')
        find('.btn-search').click

        page.within('.results') do
          expect(find(:css, '.search-results')).to have_content('Update capybara, rspec-rails, poltergeist to recent versions')
        end
      end
    end
  end

  context 'when signed out' do
    let(:project) { create(:project, :public, :repository) }

    before do
      visit(project_path(project))
    end

    it 'finds code' do
      fill_in('search', with: 'rspec')
      click_button('Go')

      page.within('.results') do
        expect(find(:css, '.search-results')).to have_content('Update capybara, rspec-rails, poltergeist to recent versions')
      end
    end
  end
end
