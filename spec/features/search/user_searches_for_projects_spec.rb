# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for projects', :js, :disable_rate_limiter, feature_category: :global_search do
  let!(:project) { create(:project, :public, name: 'Shop') }

  context 'when signed out' do
    context 'when global_search_block_anonymous_searches_enabled is disabled' do
      before do
        stub_application_setting(global_search_block_anonymous_searches_enabled: false)
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'projects'

      it 'shows scopes when there is no search term' do
        submit_dashboard_search('')

        within_testid('search-filter') do
          expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
        end
      end

      it 'finds a project' do
        visit(search_path)
        submit_dashboard_search(project.name[0..3])

        expect(page).to have_link(project.name)
      end

      it 'preserves the group being searched in' do
        visit(search_path(group_id: project.namespace.id))

        submit_dashboard_search('foo')

        expect(find('#group_id', visible: false).value).to eq(project.namespace.id.to_s)
      end

      it 'preserves the project being searched in' do
        visit(search_path(project_id: project.id))

        submit_dashboard_search('foo')

        expect(find('#project_id', visible: false).value).to eq(project.id.to_s)
      end
    end

    context 'when global_search_block_anonymous_searches_enabled is enabled' do
      before do
        stub_application_setting(global_search_block_anonymous_searches_enabled: true)
      end

      it 'is redirected to login page' do
        visit(search_path)
        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end
  end
end
