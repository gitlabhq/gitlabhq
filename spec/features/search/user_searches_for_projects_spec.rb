# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for projects' do
  let!(:project) { create(:project, :public, name: 'Shop') }

  context 'when signed out' do
    include_examples 'top right search form'

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
end
