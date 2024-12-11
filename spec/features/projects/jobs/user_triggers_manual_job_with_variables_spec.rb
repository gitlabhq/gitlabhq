# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User triggers manual job with variables', :js, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let!(:build) { create(:ci_build, :manual, pipeline: pipeline) }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
    project.add_maintainer(user)
    project.enable_ci

    sign_in(user)

    visit(project_job_path(project, build))
  end

  it 'passes values correctly' do
    within_testid('ci-variable-row') do
      find_by_testid('ci-variable-key').set('key_name')
      find_by_testid('ci-variable-value').set('key_value')
    end

    find_by_testid('run-manual-job-btn').click

    wait_for_requests

    expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
      hash_including('key' => 'key_name', 'value' => 'key_value'))
  end
end
