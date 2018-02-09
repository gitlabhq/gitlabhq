require 'rails_helper'

describe 'Merge request > User sees pipelines from forked project', :js do
  let(:target_project) { create(:project, :public, :repository) }
  let(:user) { target_project.creator }
  let(:fork_project) { create(:project, :repository, forked_from_project: target_project) }
  let!(:merge_request) do
    create(:merge_request_with_diffs, source_project: fork_project,
                                      target_project: target_project,
                                      description: 'Test merge request')
  end
  let(:pipeline) do
    create(:ci_pipeline,
           project: fork_project,
           sha: merge_request.diff_head_sha,
           ref: merge_request.source_branch)
  end

  before do
    create(:ci_build, pipeline: pipeline, name: 'rspec')
    create(:ci_build, pipeline: pipeline, name: 'spinach')

    sign_in(user)
    visit project_merge_request_path(target_project, merge_request)
  end

  it 'user visits a pipelines page' do
    page.within('.merge-request-tabs') { click_link 'Pipelines' }

    page.within('.ci-table') do
      expect(page).to have_content(pipeline.id)
    end
  end
end
