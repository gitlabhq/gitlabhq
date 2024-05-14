# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees suggest pipeline', :js, feature_category: :continuous_integration do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.source_project }
  let(:user) { project.creator }
  let(:suggest_pipeline_enabled) { true }

  before do
    stub_application_setting(suggest_pipeline_enabled: suggest_pipeline_enabled, auto_devops_enabled: false)
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'shows the suggest pipeline widget and then allows dismissal correctly' do
    content = 'GitLab CI/CD can automatically build, test, and deploy your application'
    expect(page).to have_content(content)

    page.within '.mr-pipeline-suggest' do
      find_by_testid('close').click
    end

    wait_for_requests

    expect(page).not_to have_content(content)

    # Reload so we know the user callout was registered
    visit page.current_url

    expect(page).not_to have_content(content)
  end

  it 'takes the user to the pipeline editor with a pre-filled CI config file form' do
    expect(page).to have_content('GitLab CI/CD can automatically build, test, and deploy your application')

    page.within '.mr-pipeline-suggest' do
      find_by_testid('ok').click
    end

    wait_for_requests

    # Editor shows template
    expect(page).to have_content('This file is a template, and might need editing before it works on your project.')

    # Commit form is shown
    expect(page).to have_button('Commit changes')
  end

  context 'when feature setting is disabled' do
    let(:suggest_pipeline_enabled) { false }

    it 'does not show the suggest pipeline widget' do
      expect(page).not_to have_content('Are you adding technical debt or code vulnerabilities?')
    end
  end
end
