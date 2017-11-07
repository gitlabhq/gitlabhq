require 'spec_helper'

describe 'Merge request with sast', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  let(:merge_request) do
    create(:merge_request_with_diffs,
           source_project: project,
           target_project: project,
           author: user,
           title: 'Bug NS-04')
  end

  let(:pipeline) do
    create(:ci_pipeline,
           :success,
           project: project,
           sha: merge_request.diff_head_sha,
           ref: merge_request.source_branch,
           head_pipeline_of: merge_request)
  end

  let!(:build) do
    create(
      :ci_build,
      :artifacts,
      :success,
      name: 'sast',
      pipeline: pipeline,
      options: {
        artifacts: {
          paths: ['gl-sast-report.json']
        }
      }
    )
  end

  before do
    stub_licensed_features(sast: true)
    project.add_developer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
    wait_for_requests
  end

  it 'shows sast information' do
    expect(page).to have_content('1 security vulnerability detected')
  end

  it 'expands the information section' do
    click_button('Expand')

    expect(page).to have_content('message name goes here')
    expect(page).to have_content('file name goes here')
  end
end
