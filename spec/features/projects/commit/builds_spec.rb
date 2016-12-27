require 'spec_helper'

feature 'project commit builds' do
  given(:project) { create(:project) }

  background do
    user = create(:user)
    project.team << [user, :master]
    login_as(user)
  end

  context 'when no builds triggered yet' do
    background do
      create(:ci_pipeline, project: project,
                           sha: project.commit.sha,
                           ref: 'master')
    end

    scenario 'user views commit builds page' do
      visit builds_namespace_project_commit_path(project.namespace,
                                                 project, project.commit.sha)

      expect(page).to have_content('Builds')
    end
  end
end
