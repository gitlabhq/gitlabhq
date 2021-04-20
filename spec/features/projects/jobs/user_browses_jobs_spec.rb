# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User browses jobs' do
  let!(:build) { create(:ci_build, :coverage, pipeline: pipeline) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    stub_feature_flags(jobs_table_vue: false)
    project.add_maintainer(user)
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

  context 'with a failed job' do
    let!(:build) { create(:ci_build, :coverage, :failed, pipeline: pipeline) }

    it 'displays a tooltip with the failure reason' do
      page.within('.ci-table') do
        failed_job_link = page.find('.ci-failed')
        expect(failed_job_link[:title]).to eq('Failed - (unknown failure)')
      end
    end
  end
end
