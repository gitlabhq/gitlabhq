# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project CI/CD analytics', :js, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)

    create(:ci_empty_pipeline, project: project, ref: 'master', status: 'success', sha: project.commit.id)

    visit charts_project_pipelines_path(project)
  end

  it 'renders the charts page' do
    expect(page).to have_content('CI/CD Analytics')
    expect(page).to have_content('Pipelines charts')
    expect(page).to have_content('Pipeline durations for the last 30 commits')
  end
end
