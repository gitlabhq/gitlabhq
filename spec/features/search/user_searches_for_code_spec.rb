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
        find_by_testid('project-filter').click

        wait_for_requests

        within_testid('project-filter') do
          select_listbox_item(project.name)
        end
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'blobs' do
        let(:additional_params) { { project_id: project.id } }
      end

      context 'when searching code' do
        let(:expected_result) { 'Update capybara, rspec-rails, poltergeist to recent versions' }

        before do
          submit_dashboard_search('rspec')
          select_search_scope('Code')
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

        context 'no search term' do
          before do
            submit_dashboard_search('dashboard_search')
            # fill_in('dashboard_search', with: '')
            # find('.gl-search-box-by-click-search-button').click
          end

          it 'shows scopes' do
            within_testid('search-filter') do
              expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
            end
          end
        end
      end

      it 'search multiple words with refs switching' do
        expected_result = 'Use `snake_case` for naming files'
        search = 'for naming files'
        ref_selector = 'v1.0.0'

        submit_dashboard_search(search)
        select_search_scope('Code')

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

    it 'no ref switcher shown in issue result summary' do
      issue = create(:issue, title: 'test', project: project)
      visit(project_tree_path(project))

      submit_search('test')
      select_search_scope('Code')

      expect(page).to have_selector('.ref-selector')

      select_search_scope('Issue')

      expect(find(:css, '.results')).to have_link(issue.title)
      expect(page).not_to have_selector('.ref-selector')
    end
  end

  context 'when signed out' do
    context 'when block_anonymous_global_searches is enabled' do
      it 'is redirected to login page' do
        visit(search_path)

        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end
  end
end
