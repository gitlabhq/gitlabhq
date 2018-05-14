require 'spec_helper'

describe 'User browses jobs' do
  let!(:build) { create(:ci_build, :coverage, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    project.enable_ci
    project.update_attribute(:build_coverage_regex, /Coverage (\d+)%/)

    sign_in(user)

    visit(project_jobs_path(project))
  end

  it 'shows the coverage' do
    page.within('td.coverage') do
      expect(page).to have_content('99.9%')
    end
  end

  it 'shows the "CI Lint" button' do
    page.within('.nav-controls') do
      ci_lint_tool_link = page.find_link('CI lint')

      expect(ci_lint_tool_link[:href]).to end_with(project_ci_lint_path(project))
    end
  end

  context 'with a failed job' do
    let!(:build) { create(:ci_build, :coverage, :failed, pipeline: pipeline) }

    it 'displays a tooltip with the failure reason' do
      page.within('.ci-table') do
        failed_job_link = page.find('.ci-failed')
        expect(failed_job_link[:title]).to eq('Failed <br> (unknown failure)')
      end
    end
  end
end
