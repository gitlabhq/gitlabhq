# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit > User view commits', feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  shared_examples 'can view commits' do
    it 'lists the correct number of commits' do
      expect(page).to have_selector('#commits-list > li:nth-child(2) > ul', count: 1)
    end
  end

  describe 'Commits List' do
    context 'when project is public' do
      let(:project) { create(:project, :public, :repository, group: group) }

      before do
        visit project_commits_path(project)
      end

      it_behaves_like 'can view commits'
    end

    context 'when project is public with private repository' do
      let(:project) { create(:project, :public, :repository, :repository_private, group: group) }

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
      let(:project) { create(:project, :private, :repository, group: group) }

      context 'and user is an inherited member from the group' do
        context 'and user is a guest' do
          before do
            group.add_guest(user)
            sign_in(user)
            visit project_commits_path(project)
          end

          it 'renders not found' do
            expect(page).to have_title('Not Found')
            expect(page).to have_content('Page Not Found')
          end
        end
      end
    end
  end
end
