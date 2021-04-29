# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'project commit pipelines', :js do
  let(:project) { create(:project, :repository) }

  before do
    create(:ci_pipeline, project: project,
                         sha: project.commit.sha,
                         ref: 'master')

    user = create(:user)
    project.add_maintainer(user)
    sign_in(user)

    visit pipelines_project_commit_path(project, project.commit.sha)
  end

  context 'when no builds triggered yet' do
    it 'shows the ID of the first pipeline' do
      page.within('.pipelines .ci-table') do
        expect(page).to have_content project.ci_pipelines[0].id # pipeline ids
      end
    end
  end

  context 'with no related merge requests' do
    it 'shows the correct text for no related MRs' do
      wait_for_requests

      page.within('.merge-request-info') do
        expect(page).not_to have_selector '.gl-spinner'
        expect(page).to have_content 'No related merge requests found'
      end
    end
  end
end
