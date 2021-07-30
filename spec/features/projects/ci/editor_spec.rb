# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  let(:default_branch) { 'main' }
  let(:other_branch) { 'test' }

  before do
    sign_in(user)
    project.add_developer(user)

    project.repository.create_file(user, project.ci_config_path_or_default, 'Default Content', message: 'Create CI file for main', branch_name: default_branch)
    project.repository.create_file(user, project.ci_config_path_or_default, 'Other Content', message: 'Create CI file for test', branch_name: other_branch)

    visit project_ci_pipeline_editor_path(project)
    wait_for_requests
  end

  it 'user sees the Pipeline Editor page' do
    expect(page).to have_content('Pipeline Editor')
  end

  context 'branch switcher' do
    before do
      stub_feature_flags(pipeline_editor_branch_switcher: true)
    end

    def switch_to_branch(branch)
      find('[data-testid="branch-selector"]').click

      page.within '[data-testid="branch-selector"]' do
        click_button branch
        wait_for_requests
      end
    end

    it 'displays current branch' do
      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(default_branch)
        expect(page).not_to have_content(other_branch)
      end
    end

    it 'displays updated current branch after switching branches' do
      switch_to_branch(other_branch)

      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(other_branch)
        expect(page).not_to have_content(default_branch)
      end
    end
  end
end
