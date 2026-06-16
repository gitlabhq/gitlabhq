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

  # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/601317.
  #
  # Feature specs run with the vue3_migrate_jobs flag enabled by default, so this
  # exercises the Vue 3 compat build. Adding a variable flips the last row's
  # `canRemove(index)` from false to true, switching its delete button between the
  # v-else placeholder and the v-if branch that carries `v-gl-tooltip`. When those
  # same-tag branches lack distinct keys, @vue/compat patches one onto the other in
  # place and throws in `invokeDirectiveHook` ("Cannot read properties of undefined
  # (reading 'value')") because the new vnode has more directives than the old one.
  # The crash aborts the component update, so no further rows are ever committed.
  #
  # The real fix injects keys on same-tag v-if/v-else branches for the
  # `?vue3`-infected build (config/webpack.config.js wiring vue2_compiler.js). This
  # only reproduces with the real webpack-compiled Vue 3 compat build in a browser;
  # jsdom/jest uses @vue/compiler-dom and does not exercise this codepath, so the
  # regression must be guarded here, at the feature level.
  it 'allows adding more than one variable', :aggregate_failures do
    click_button 'Variables'

    expect(page).to have_selector('[data-testid="ci-variable-row"]', count: 1)

    enter_key_in_last_row('key_one')
    expect(page).to have_selector('[data-testid="ci-variable-row"]', count: 2)

    enter_key_in_last_row('key_two')
    expect(page).to have_selector('[data-testid="ci-variable-row"]', count: 3)
  end

  # Entering a key in the last row fires its `change` handler (`addEmptyVariable`),
  # which pushes the next empty row.
  def enter_key_in_last_row(key)
    # The preceding count assertion guarantees the rows exist, so `all(...).last` is
    # safe here. A `:last-child` selector would not work: help-text divs follow the
    # rows inside the collapse, so no `ci-variable-row` is ever the last child.
    row = all('[data-testid="ci-variable-row"]').last
    within(row) do
      field = find_by_testid('ci-variable-key')
      field.set(key)
      field.send_keys(:tab) # blur to fire the `change` handler
    end
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

    it 'displays job inputs form and passes values correctly' do
      expect(page).to have_content('Inputs')

      fill_in_job_input('environment', with: 'production')

      find_by_testid('run-manual-job-btn').click
      wait_for_requests

      expect(build.inputs.map(&:name)).to contain_exactly('environment')
      expect(build.inputs.find_by(name: 'environment').value).to eq('production')
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
