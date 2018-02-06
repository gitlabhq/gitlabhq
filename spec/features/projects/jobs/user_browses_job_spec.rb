require 'spec_helper'

describe 'User browses a job', :js do
  let!(:build) { create(:ci_build, :running, :coverage, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    project.enable_ci
    build.success
    build.trace.set('job trace')

    sign_in(user)

    visit(project_job_path(project, build))
  end

  it 'erases the job log' do
    expect(page).to have_content("Job ##{build.id}")
    expect(page).to have_css('#build-trace')

    accept_confirm { click_link('Erase') }

    expect(page).to have_no_css('.artifacts')
    expect(build).not_to have_trace
    expect(build.artifacts_file.exists?).to be_falsy
    expect(build.artifacts_metadata.exists?).to be_falsy

    page.within('.erased') do
      expect(page).to have_content('Job has been erased')
    end

    expect(build.project.running_or_pending_build_count).to eq(build.project.builds.running_or_pending.count(:all))
  end
end
