# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views empty wiki' do
  let(:user) { create(:user) }
  let(:confluence_link) { 'Enable the Confluence Wiki integration' }
  let(:element) { page.find('.row.empty-state') }

  shared_examples 'empty wiki and accessible issues' do
    it 'show "issue tracker" message' do
      visit(project_wikis_path(project))

      expect(element).to have_content('This project has no wiki pages')
      expect(element).to have_content('You must be a project member')
      expect(element).to have_content('improve the wiki for this project')
      expect(element).to have_link("issue tracker", href: project_issues_path(project))
      expect(element).to have_link("Suggest wiki improvement", href: new_project_issue_path(project))
      expect(element).to have_no_link(confluence_link)
    end
  end

  shared_examples 'empty wiki and non-accessible issues' do
    it 'does not show "issue tracker" message' do
      visit(project_wikis_path(project))

      expect(element).to have_content('This project has no wiki pages')
      expect(element).to have_content('You must be a project member')
      expect(element).to have_no_link('Suggest wiki improvement')
      expect(element).to have_no_link(confluence_link)
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
    let(:project) { create(:project, :public) }

    before do
      sign_in(user)
      project.add_developer(user)
    end

    it 'shows "create first page" message' do
      visit(project_wikis_path(project))

      expect(element).to have_content('your project', count: 2)

      element.click_link 'Create your first page'

      expect(page).to have_button('Create page')
    end

    it 'does not show the "enable confluence" button' do
      visit(project_wikis_path(project))

      expect(element).to have_no_link(confluence_link)
    end
  end

  context 'when user is logged in and an admin' do
    let(:project) { create(:project, :public, :wiki_repo) }

    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    it 'shows the "enable confluence" button' do
      visit(project_wikis_path(project))

      expect(element).to have_link(confluence_link)
    end

    it 'does not show "enable confluence" button if confluence is already enabled' do
      create(:confluence_service, project: project)

      visit(project_wikis_path(project))

      expect(element).to have_no_link(confluence_link)
    end
  end
end
