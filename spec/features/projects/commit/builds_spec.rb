require 'spec_helper'

feature 'project commit pipelines', :js do
  given(:project) { create(:project, :repository) }

  background do
    user = create(:user)
    project.add_master(user)
    sign_in(user)
  end

  context 'when no builds triggered yet' do
    background do
      create(:ci_pipeline, project: project,
                           sha: project.commit.sha,
                           ref: 'master')
    end

    scenario 'user views commit pipelines page' do
      visit pipelines_project_commit_path(project, project.commit.sha)

      page.within('.table-holder') do
        expect(page).to have_content project.pipelines[0].id     # pipeline ids
      end
    end
  end
end
