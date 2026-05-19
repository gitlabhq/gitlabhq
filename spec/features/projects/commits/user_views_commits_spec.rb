# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit > User views commits', feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  shared_examples 'private project access denied' do
    context 'when project is private' do
      let_it_be(:project) { create_default(:project, :private, :repository, group: group) }

      context 'and user is an inherited member from the group' do
        context 'and user is a guest' do
          before_all do
            group.add_guest(user)
          end

          it 'renders not found' do
            sign_in(user)
            visit project_commits_path(project)

            expect(page).to have_title('Not Found')
            expect(page).to have_content('Page not found')
          end
        end
      end
    end
  end

  shared_examples 'has expected number of commits' do
    it 'lists the correct number of commits' do
      visit project_commits_path(project)

      expect(page).to have_selector('#commits-list ol > li:nth-child(2) > ul', count: 1)
    end
  end

  shared_examples 'has expected number of commits with refactor', :js do
    it 'lists the correct number of commits' do
      visit project_commits_path(project)
      wait_for_requests

      expect(page).to have_selector(
        'li[data-testid="daily-commits"]:nth-child(2) > ul.daily-commits-item',
        count: 1
      )
    end
  end

  describe 'Commits List' do
    context 'when project is public' do
      let_it_be(:project) { create_default(:project, :public, :repository, group: group) }

      it_behaves_like 'has expected number of commits'
    end

    context 'when project is public with private repository' do
      let_it_be(:project) { create_default(:project, :public, :repository, :repository_private, group: group) }

      context 'and user is an inherited member from the group' do
        context 'and user is a guest' do
          before_all do
            group.add_guest(user)
            sign_in(user)
          end

          it 'lists the correct number of commits' do
            visit project_commits_path(project)

            expect(page).to have_selector('#commits-list ol > li:nth-child(2) > ul', count: 1)
          end
        end
      end
    end

    it_behaves_like 'private project access denied'

    context 'when project_commits_refactor is enabled' do
      before do
        stub_feature_flags(project_commits_refactor: true)
      end

      context 'when project is public' do
        let_it_be(:project) { create_default(:project, :public, :repository, group: group) }

        it_behaves_like 'has expected number of commits with refactor'
      end

      context 'when project is public with private repository' do
        let_it_be(:project) { create_default(:project, :public, :repository, :repository_private, group: group) }

        context 'and user is an inherited member from the group' do
          context 'and user is a guest' do
            before_all do
              group.add_guest(user)
            end

            before do
              sign_in(user)
            end

            it_behaves_like 'has expected number of commits with refactor'
          end
        end
      end

      it_behaves_like 'private project access denied'
    end
  end

  describe 'Single commit', :js do
    let_it_be(:project) { create_default(:project, :public, :repository, group: group) }
    let_it_be(:sha) { sample_commit.sha }

    it 'passes axe automated accessibility testing' do
      visit project_commit_path(project, sha)

      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block',
        :'link-name', :'valid-lang'
    end

    context 'when displayed with rapid_diffs' do
      let_it_be(:diffs) { project.commit(sha).diffs }

      before do
        visit project_commit_path(project, sha)

        wait_for_requests
      end

      it_behaves_like 'Rapid Diffs application'
    end
  end
end
