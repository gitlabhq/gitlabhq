# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for projects', :js do
  let!(:project) { create(:project, :public, name: 'Shop') }

  context 'when signed out' do
    context 'when block_anonymous_global_searches is disabled' do
      before do
        stub_feature_flags(block_anonymous_global_searches: false)
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'projects'

      it 'finds a project' do
        visit(search_path)

        fill_in('dashboard_search', with: project.name[0..3])
        click_button('Search')

        expect(page).to have_link(project.name)
      end

      it 'preserves the group being searched in' do
        visit(search_path(group_id: project.namespace.id))

        submit_search('foo')

        expect(find('#group_id', visible: false).value).to eq(project.namespace.id.to_s)
      end

      it 'preserves the project being searched in' do
        visit(search_path(project_id: project.id))

        submit_search('foo')

        expect(find('#project_id', visible: false).value).to eq(project.id.to_s)
      end
    end

    context 'when block_anonymous_global_searches is enabled' do
      it 'is redirected to login page' do
        visit(search_path)
        expect(page).to have_content('You must be logged in to search across all of GitLab')
      end
    end
  end
end
