# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js, feature_category: :pipeline_composition do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:branch_with_broken_yaml) { 'broken-yaml' }

  let(:content_with_broken_yaml) do
    <<~YAML
      job_a:
        script: echo first
         misindented_key: echo second
    YAML
  end

  before do
    sign_in(user)
    project.add_developer(user)
    project.repository.create_file(
      user,
      project.ci_config_path_or_default,
      content_with_broken_yaml,
      message: 'Create CI file with broken YAML',
      branch_name: branch_with_broken_yaml
    )

    visit project_ci_pipeline_editor_path(project, branch_name: branch_with_broken_yaml)
  end

  it 'shows a diagnostic from the YAML language worker', :aggregate_failures do
    page.within('#source-editor-') do
      expect(page).to have_content('script: echo first')

      # The worker computes diagnostics asynchronously, so retry the
      # "go to next problem" shortcut until they arrive.
      wait_for('YAML worker diagnostic') do
        find('textarea').send_keys(:f8)
        page.has_content?('Nested mappings are not allowed in compact mappings', wait: 1)
      end
    end

    expect(page).to have_content('Nested mappings are not allowed in compact mappings')
  end
end
