# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for code' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'when signed in' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'finds a file' do
      visit(project_path(project))

      submit_search('application.js')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'application.js')
      expect(page).to have_selector('.file-content .code')
      expect(page).to have_selector("span.line[lang='javascript']")
      expect(page).to have_link('application.js', href: %r{master/files/js/application.js})
    end

    context 'when on a project page', :js do
      before do
        visit(search_path)
        find('[data-testid="project-filter"]').click

        wait_for_requests

        page.within('[data-testid="project-filter"]') do
          click_on(project.name)
        end
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'blobs'

      it 'finds code' do
        fill_in('dashboard_search', with: 'rspec')
        find('.btn-search').click

        expect(page).to have_selector('.results', text: 'Update capybara, rspec-rails, poltergeist to recent versions')

        find("#L3").click
        expect(current_url).to match(%r{master/.gitignore#L3})
      end

      it 'search mutiple words with refs switching' do
        expected_result = 'Use `snake_case` for naming files'
        search = 'for naming files'

        fill_in('dashboard_search', with: search)
        find('.btn-search').click

        expect(page).to have_selector('.results', text: expected_result)

        find('.js-project-refs-dropdown').click
        find('.dropdown-page-one .dropdown-content').click_link('v1.0.0')

        expect(page).to have_selector('.results', text: expected_result)

        expect(find_field('dashboard_search').value).to eq(search)
        expect(find("#L1502")[:href]).to match(%r{v1.0.0/files/markdown/ruby-style-guide.md#L1502})
      end
    end

    context 'search code within refs', :js do
      let(:ref_name) { 'v1.0.0' }

      before do
        visit(project_tree_path(project, ref_name))

        submit_search('gitlab-grack')
        select_search_scope('Code')
      end

      it 'shows ref switcher in code result summary' do
        expect(find('.js-project-refs-dropdown')).to have_text(ref_name)
      end
      it 'persists branch name across search' do
        find('.btn-search').click
        expect(find('.js-project-refs-dropdown')).to have_text(ref_name)
      end

      #  this example is use to test the desgine that the refs is not
      #  only repersent the branch as well as the tags.
      it 'ref swither list all the branchs and tags' do
        find('.js-project-refs-dropdown').click
        expect(find('.dropdown-page-one .dropdown-content')).to have_link('sha-starting-with-large-number')
        expect(find('.dropdown-page-one .dropdown-content')).to have_link('v1.0.0')
      end

      it 'search result changes when refs switched' do
        expect(find('.results')).not_to have_content('path = gitlab-grack')

        find('.js-project-refs-dropdown').click
        find('.dropdown-page-one .dropdown-content').click_link('master')

        expect(page).to have_selector('.results', text: 'path = gitlab-grack')
      end

      it 'persist refs over browser tabs' do
        ref = 'feature'
        find('.js-project-refs-dropdown').click
        link = find_link(ref)[:href]
        expect(link.include?("repository_ref=" + ref)).to be(true)
      end
    end

    it 'no ref switcher shown in issue result summary', :js do
      issue = create(:issue, title: 'test', project: project)
      visit(project_tree_path(project))

      submit_search('test')
      select_search_scope('Code')

      expect(page).to have_selector('.js-project-refs-dropdown')

      select_search_scope('Issues')

      expect(find(:css, '.results')).to have_link(issue.title)
      expect(page).not_to have_selector('.js-project-refs-dropdown')
    end
  end

  context 'when signed out' do
    let(:project) { create(:project, :public, :repository) }

    before do
      visit(project_path(project))
    end

    it 'finds code' do
      submit_search('rspec')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'Update capybara, rspec-rails, poltergeist to recent versions')
    end
  end
end
