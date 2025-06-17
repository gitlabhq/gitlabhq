# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit > User view commits', feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  shared_examples 'can view commits' do
    it 'lists the correct number of commits' do
      expect(page).to have_selector('#commits-list > li:nth-child(2) > ul', count: 1)
    end
  end

  describe 'Commits List' do
    context 'when project is public' do
      let_it_be(:project) { create_default(:project, :public, :repository, group: group) }

      before do
        visit project_commits_path(project)
      end

      it_behaves_like 'can view commits'
    end

    context 'when project is public with private repository' do
      let_it_be(:project) { create_default(:project, :public, :repository, :repository_private, group: group) }

      context 'and user is an inherited member from the group' do
        context 'and user is a guest' do
          before do
            group.add_guest(user)
            sign_in(user)
            visit project_commits_path(project)
          end

          it_behaves_like 'can view commits'
        end
      end
    end

    context 'when project is private' do
      let_it_be(:project) { create_default(:project, :private, :repository, group: group) }

      context 'and user is an inherited member from the group' do
        context 'and user is a guest' do
          before do
            group.add_guest(user)
            sign_in(user)
            visit project_commits_path(project)
          end

          it 'renders not found' do
            expect(page).to have_title('Not Found')
            expect(page).to have_content('Page not found')
          end
        end
      end
    end
  end

  describe 'Single commit', :js do
    let_it_be(:project) { create_default(:project, :public, :repository, group: group) }
    let_it_be(:sha) { sample_commit.sha }

    it 'passes axe automated accessibility testing' do
      visit project_commit_path(project, sha)

      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'color-contrast', :'link-in-text-block',
        :'link-name', :'valid-lang'
    end

    context 'when displayed with rapid_diffs' do
      let_it_be(:diffs) { project.commit(sha).diffs }

      before do
        visit project_commit_path(project, sha, rapid_diffs: true)

        wait_for_requests
      end

      it_behaves_like 'Rapid Diffs application'
    end
  end
end
