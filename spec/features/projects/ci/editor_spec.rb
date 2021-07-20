# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)

    visit project_ci_pipeline_editor_path(project)
  end

  it 'user sees the Pipeline Editor page' do
    expect(page).to have_content('Pipeline Editor')
  end
end
