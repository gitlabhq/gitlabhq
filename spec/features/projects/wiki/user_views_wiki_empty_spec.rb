# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views empty wiki' do
  let(:user) { create(:user) }

  shared_examples 'empty wiki and accessible issues' do
    it 'show "issue tracker" message' do
      visit(project_wikis_path(project))

      element = page.find('.row.empty-state')

      expect(element).to have_content('This project has no wiki pages')
      expect(element).to have_link("issue tracker", href: project_issues_path(project))
      expect(element).to have_link("Suggest wiki improvement", href: new_project_issue_path(project))
    end
  end

  shared_examples 'empty wiki and non-accessible issues' do
    it 'does not show "issue tracker" message' do
      visit(project_wikis_path(project))

      element = page.find('.row.empty-state')

      expect(element).to have_content('This project has no wiki pages')
      expect(element).to have_no_link('Suggest wiki improvement')
    end
  end

  context 'when user is logged out and issue tracker is public' do
    let(:project) { create(:project, :public, :wiki_repo) }

    it_behaves_like 'empty wiki and accessible issues'
  end

  context 'when user is logged in and not a member' do
    let(:project) { create(:project, :public, :wiki_repo) }

    before do
      sign_in(user)
    end

    it_behaves_like 'empty wiki and accessible issues'
  end

  context 'when issue tracker is private' do
    let(:project) { create(:project, :public, :wiki_repo, :issues_private) }

    it_behaves_like 'empty wiki and non-accessible issues'
  end

  context 'when issue tracker is disabled' do
    let(:project) { create(:project, :public, :wiki_repo, :issues_disabled) }

    it_behaves_like 'empty wiki and non-accessible issues'
  end

  context 'when user is logged in and a member' do
    let(:project) { create(:project, :public, :wiki_repo) }

    before do
      sign_in(user)
      project.add_developer(user)
    end

    it 'show "create first page" message' do
      visit(project_wikis_path(project))

      element = page.find('.row.empty-state')

      element.click_link 'Create your first page'

      expect(page).to have_button('Create page')
    end
  end
end
