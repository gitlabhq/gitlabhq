# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User searches for files', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user, :no_super_sidebar) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  describe 'project main screen' do
    context 'when project is empty' do
      let_it_be(:project) { create(:project, namespace: user.namespace) }

      before do
        visit project_path(project)
      end

      it 'does not show any result' do
        submit_search('coffee')

        expect(page).to have_content("We couldn't find any")
      end
    end

    context 'when project is not empty' do
      before do
        visit project_path(project)
      end

      it 'shows "Find file" button' do
        expect(page).to have_selector('.tree-controls .shortcuts-find-file')
      end
    end
  end

  describe 'project tree screen' do
    before do
      visit project_tree_path(project, project.default_branch)
    end

    it 'shows found files' do
      expect(page).to have_selector('.tree-controls .shortcuts-find-file')

      submit_search('coffee')

      expect(page).to have_content('coffee')
      expect(page).to have_content('CONTRIBUTING.md')
    end
  end
end
