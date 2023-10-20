# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for code', :js, :disable_rate_limiter, feature_category: :global_search do
  using RSpec::Parameterized::TableSyntax
  include ListboxHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'when signed in' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when on a project page' do
      before do
        visit(project_path(project))
      end

      it 'finds a file' do
        submit_search('application.js')
        select_search_scope('Code')

        expect(page).to have_selector('.results', text: 'application.js')
        expect(page).to have_selector('.file-content .code')
        expect(page).to have_selector("span.line[lang='javascript']")
        expect(page).to have_link('application.js', href: %r{master/files/js/application.js})
        expect(page).to have_button('Copy file path')
      end
    end

    context 'when on a project search page' do
      before do
        visit(search_path)
        find('[data-testid="project-filter"]').click

        wait_for_requests

        page.within('[data-testid="project-filter"]') do
          click_on(project.name)
        end
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'blobs' do
        let(:additional_params) { { project_id: project.id } }
      end

      context 'when searching code' do
        let(:expected_result) { 'Update capybara, rspec-rails, poltergeist to recent versions' }

        before do
          fill_in('dashboard_search', with: 'rspec')
          find('.gl-search-box-by-click-search-button').click
        end

        it 'finds code and links to blob' do
          expect(page).to have_selector('.results', text: expected_result)

          find("#blob-L3").click
          expect(current_url).to match(%r{blob/master/.gitignore#L3})
        end

        it 'finds code and links to blame' do
          expect(page).to have_selector('.results', text: expected_result)

          find("#blame-L3").click
          expect(current_url).to match(%r{blame/master/.gitignore#L3})
        end

        it_behaves_like 'code highlight' do
          subject { page }
        end
      end

      it 'search multiple words with refs switching' do
        expected_result = 'Use `snake_case` for naming files'
        search = 'for naming files'
        ref_selector = 'v1.0.0'

        fill_in('dashboard_search', with: search)
        find('.gl-search-box-by-click-search-button').click

        expect(page).to have_selector('.results', text: expected_result)

        click_button 'master'
        wait_for_requests

        select_listbox_item(ref_selector)

        expect(page).to have_selector('.results', text: expected_result)

        expect(find_field('dashboard_search').value).to eq(search)
        expect(find("#blob-L1502")[:href]).to match(%r{blob/v1.0.0/files/markdown/ruby-style-guide.md#L1502})
        expect(find("#blame-L1502")[:href]).to match(%r{blame/v1.0.0/files/markdown/ruby-style-guide.md#L1502})
      end
    end

    context 'when header search' do
      context 'search code within refs' do
        let(:ref_name) { 'v1.0.0' }

        before do
          visit(project_tree_path(project, ref_name))

          submit_search('gitlab-grack')
          select_search_scope('Code')
        end

        it 'shows ref switcher in code result summary' do
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        it 'persists branch name across search' do
          find('.gl-search-box-by-click-search-button').click
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        #  this example is use to test the design that the refs is not
        #  only represent the branch as well as the tags.
        it 'ref switcher list all the branches and tags' do
          find('.ref-selector').click
          wait_for_requests

          page.within('.ref-selector') do
            expect(page).to have_selector('li', text: 'add-ipython-files')
            expect(page).to have_selector('li', text: 'v1.0.0')
          end
        end

        it 'search result changes when refs switched' do
          expect(find('.results')).not_to have_content('path = gitlab-grack')

          find('.ref-selector').click
          wait_for_requests

          select_listbox_item('add-ipython-files')

          expect(page).to have_selector('.results', text: 'path = gitlab-grack')
        end
      end
    end

    it 'no ref switcher shown in issue result summary' do
      issue = create(:issue, title: 'test', project: project)
      visit(project_tree_path(project))

      submit_search('test')
      select_search_scope('Code')

      expect(page).to have_selector('.ref-selector')

      select_search_scope('Issues')

      expect(find(:css, '.results')).to have_link(issue.title)
      expect(page).not_to have_selector('.ref-selector')
    end
  end

  context 'when signed out' do
    context 'when block_anonymous_global_searches is enabled' do
      it 'is redirected to login page' do
        visit(search_path)

        expect(page).to have_content('You must be logged in to search across all of GitLab')
      end
    end
  end
end
