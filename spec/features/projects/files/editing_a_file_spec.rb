require 'spec_helper'

feature 'User wants to edit a file' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:commit_params) do
    {
      start_branch: project.default_branch,
      branch_name: project.default_branch,
      commit_message: "Committing First Update",
      file_path: ".gitignore",
      file_content: "First Update",
      last_commit_sha: Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch,
                                                         ".gitignore").sha
    }
  end

  background do
    project.add_master(user)
    sign_in user
    visit project_edit_blob_path(project,
                                           File.join(project.default_branch, '.gitignore'))
  end

  scenario 'file has been updated since the user opened the edit page' do
    Files::UpdateService.new(project, user, commit_params).execute

    click_button 'Commit changes'

    expect(page).to have_content 'Someone edited the file the same time you did.'
  end
end
