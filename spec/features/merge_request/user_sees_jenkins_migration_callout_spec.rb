# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees Jenkins migration callout', :js, feature_category: :continuous_integration do
  let_it_be_with_reload(:merge_request) { create(:merge_request) }
  let_it_be_with_reload(:project) { merge_request.source_project }
  let_it_be_with_reload(:user) { project.creator }
  let_it_be_with_reload(:integration) { create(:jenkins_integration, push_events: true, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    stub_application_setting(auto_devops_enabled: false)
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'shows the Jenkins migration callout' do
    wait_for_requests

    content = 'Take advantage of simple, scalable pipelines and CI/CD enabled features. ' \
      'You can view integration results, security scans, tests, code coverage and more directly in merge requests!'
    expect(page).to have_content(content)

    page.within '.mr-pipeline-suggest' do
      find_by_testid('close').click
    end

    wait_for_requests

    expect(page).not_to have_content(content)
  end
end
