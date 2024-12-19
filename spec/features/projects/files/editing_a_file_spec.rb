# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to edit a file', :js, feature_category: :source_code_management do
  include ProjectForksHelper
  let(:project) { create(:project, :repository, :public) }
  let(:user) { project.first_owner }
  let(:commit_params) do
    {
      start_branch: project.default_branch,
      branch_name: project.default_branch,
      commit_message: "Committing First Update",
      file_path: ".gitignore",
      file_content: "First Update",
      last_commit_sha: Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch, ".gitignore").sha
    }
  end

  context 'when the user has write access' do
    before do
      sign_in user
      visit project_edit_blob_path(project, File.join(project.default_branch, '.gitignore'))
    end

    it 'file has been updated since the user opened the edit page' do
      Files::UpdateService.new(project, user, commit_params).execute

      click_button 'Commit changes'

      within_testid('commit-change-modal') do
        click_button('Commit changes')
      end

      expect(page).to have_content 'An error occurred editing the blob'
    end
  end

  context 'when the user does not have write access' do
    let(:user) { create(:user) }

    context 'and the user has a fork of the project' do
      let(:forked_project) { fork_project(project, user, namespace: user.namespace, repository: true) }

      before do
        forked_project
        sign_in user
        visit project_edit_blob_path(project, File.join(project.default_branch, '.gitignore'))
      end

      context 'and the forked project is ahead of the upstream project' do
        before do
          Files::UpdateService.new(forked_project, user, commit_params).execute
        end

        it 'renders an error message' do
          click_button 'Commit changes'

          within_testid('commit-change-modal') do
            click_button('Commit changes')
          end

          expect(page).to have_content(
            'An error occurred editing the blob'
          )
        end
      end
    end
  end
end
