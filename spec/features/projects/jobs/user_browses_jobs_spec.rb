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

      expect(ci_lint_tool_link[:href]).to end_with(ci_lint_path)
    end
  end
end
