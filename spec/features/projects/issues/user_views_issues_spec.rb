require 'spec_helper'

describe 'User views issues' do
  set(:user) { create(:user) }

  shared_examples_for 'shows issues' do
    it 'shows issues' do
      expect(page).to have_content(project.name)
        .and have_content(issue1.title)
        .and have_content(issue2.title)
        .and have_no_selector('.js-new-board-list')
    end
  end

  context 'when project is public' do
    set(:project) { create(:project_empty_repo, :public) }
    set(:issue1) { create(:issue, project: project) }
    set(:issue2) { create(:issue, project: project) }

    context 'when signed in' do
      before do
        project.add_developer(user)
        sign_in(user)

        visit(project_issues_path(project))
      end

      include_examples 'shows issues'
    end

    context 'when not signed in' do
      before do
        visit(project_issues_path(project))
      end

      include_examples 'shows issues'
    end
  end

  context 'when project is internal' do
    set(:project) { create(:project_empty_repo, :internal) }
    set(:issue1) { create(:issue, project: project) }
    set(:issue2) { create(:issue, project: project) }

    context 'when signed in' do
      before do
        project.add_developer(user)
        sign_in(user)

        visit(project_issues_path(project))
      end

      include_examples 'shows issues'
    end
  end
end
