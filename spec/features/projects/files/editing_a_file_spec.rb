require 'spec_helper'

feature 'User wants to edit a file', feature: true do
  include WaitForAjax

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:commit_params) do
    {
      source_branch: project.default_branch,
      target_branch: project.default_branch,
      commit_message: "Committing First Update",
      file_path: ".gitignore",
      file_content: "First Update",
      last_commit_sha: Gitlab::Git::Commit.last_for_path(project.repository, project.default_branch,
                                                         ".gitignore").sha
    }
  end

  background do
    project.team << [user, :master]
    login_as user
    visit namespace_project_edit_blob_path(project.namespace, project,
                                           File.join(project.default_branch, '.gitignore'))
  end

  scenario 'file has been updated since the user opened the edit page' do
    Files::UpdateService.new(project, user, commit_params).execute

    click_button 'Commit Changes'

    expect(page).to have_content 'Someone edited the file the same time you did.'
  end
end
