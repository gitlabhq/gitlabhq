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

  it 'passes variables values correctly' do
    click_button 'Variables'

    within_testid('ci-variable-row') do
      find_by_testid('ci-variable-key').set('key_name')
      find_by_testid('ci-variable-value').set('key_value')
    end

    find_by_testid('run-manual-job-btn').click

    wait_for_requests

    expect(build.job_variables.as_json(only: [:key, :value])).to contain_exactly(
      hash_including('key' => 'key_name', 'value' => 'key_value'))
  end

  context 'with job inputs', :js do
    let!(:build) do
      create(:ci_build, :manual, pipeline: pipeline, options: {
        inputs: {
          environment: { type: 'string', description: 'Target environment' },
          version: { type: 'string', default: '1.0' },
          debug: { type: 'boolean', default: false }
        }
      })
    end

    before do
      stub_feature_flags(ci_job_inputs: true)
      visit(project_job_path(project, build))
    end

    it 'displays job inputs form and passes values correctly' do
      expect(page).to have_content('Inputs')

      fill_in_job_input('environment', with: 'production')

      find_by_testid('run-manual-job-btn').click
      wait_for_requests

      expect(build.inputs.map(&:name)).to contain_exactly('environment')
      expect(build.inputs.find_by(name: 'environment').value).to eq('production')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_job_inputs: false)
        visit(project_job_path(project, build))
      end

      it 'does not display job inputs form' do
        expect(page).not_to have_content('Inputs')
        expect(page).not_to have_button('Select inputs')
      end
    end

    private

    def fill_in_job_input(input_name, with:)
      input_row = find_by_testid('input-row', text: input_name)
      within(input_row) do
        find('input[type="text"]').set(with)
      end
    end
  end
end
