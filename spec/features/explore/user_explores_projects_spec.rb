# frozen_string_literal: true

require 'spec_helper'

describe 'User explores projects' do
  let_it_be(:archived_project) { create(:project, :archived) }
  let_it_be(:internal_project) { create(:project, :internal) }
  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:public_project) { create(:project, :public) }

  context 'when not signed in' do
    context 'when viewing public projects' do
      before do
        visit(explore_projects_path)
      end

      include_examples 'shows public projects'
    end

    context 'when visibility is restricted to public' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        visit(explore_projects_path)
      end

      it 'redirects to login page' do
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  context 'when signed in' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when viewing public projects' do
      before do
        visit(explore_projects_path)
      end

      include_examples 'shows public and internal projects'
    end

    context 'when viewing most starred projects' do
      before do
        visit(starred_explore_projects_path)
      end

      include_examples 'shows public and internal projects'
    end

    context 'when viewing trending projects' do
      before do
        [archived_project, public_project].each { |project| create(:note_on_issue, project: project) }

        TrendingProject.refresh!

        visit(trending_explore_projects_path)
      end

      include_examples 'shows public projects'
    end
  end
end
