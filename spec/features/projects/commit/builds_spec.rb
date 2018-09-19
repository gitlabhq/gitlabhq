require 'spec_helper'

describe 'project commit pipelines', :js do
  let(:project) { create(:project, :repository) }

  before do
    user = create(:user)
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when no builds triggered yet' do
    before do
      create(:ci_pipeline, project: project,
                           sha: project.commit.sha,
                           ref: 'master')
    end

    it 'user views commit pipelines page' do
      visit pipelines_project_commit_path(project, project.commit.sha)

      page.within('.table-holder') do
        expect(page).to have_content project.pipelines[0].id     # pipeline ids
      end
    end
  end
end
