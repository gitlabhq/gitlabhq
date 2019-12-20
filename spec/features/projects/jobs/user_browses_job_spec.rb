# frozen_string_literal: true

require 'spec_helper'

describe 'User browses a job', :js do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let!(:build) { create(:ci_build, :success, :trace_artifact, :coverage, pipeline: pipeline) }

  before do
    project.add_maintainer(user)
    project.enable_ci

    sign_in(user)

    visit(project_job_path(project, build))
  end

  it 'erases the job log', :js do
    wait_for_requests

    expect(page).to have_content("Job ##{build.id}")
    expect(page).to have_css('.job-log')

    # scroll to the top of the page first
    execute_script "window.scrollTo(0,0)"
    accept_confirm { find('.js-erase-link').click }

    expect(page).to have_no_css('.artifacts')
    expect(build).not_to have_trace
    expect(build.artifacts_file.present?).to be_falsy
    expect(build.artifacts_metadata.present?).to be_falsy

    expect(page).to have_content('Job has been erased')
  end

  context 'with a failed job' do
    let!(:build) { create(:ci_build, :failed, :trace_artifact, pipeline: pipeline) }

    it 'displays the failure reason' do
      wait_for_all_requests
      within('.builds-container') do
        expect(page).to have_selector(
          ".build-job > a[data-original-title='test - failed - (unknown failure)']")
      end
    end
  end

  context 'when a failed job has been retried' do
    let!(:build_retried) { create(:ci_build, :failed, :retried, :trace_artifact, pipeline: pipeline) }

    it 'displays the failure reason and retried label' do
      wait_for_all_requests
      within('.builds-container') do
        expect(page).to have_selector(
          ".build-job > a[data-original-title='test - failed - (unknown failure) (retried)']")
      end
    end
  end
end
