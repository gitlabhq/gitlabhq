require 'spec_helper'

describe 'Merge request with sast', :js do
  let(:user) { create(:user) }
  let(:project) { create :project, :repository }
  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end
  let(:build) do
    create(
      :ci_build,
      :artifacts,
      name: 'sast',
      pipeline: pipeline,
      options: {
        artifacts: {
          paths: ['gl-sast-report.json']
        }
      }
    )
  end
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before do
    allow(merge_request).to receive(:sast_artifact).and_return(build)
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
