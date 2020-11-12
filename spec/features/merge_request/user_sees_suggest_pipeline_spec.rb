# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees suggest pipeline', :js do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.source_project }
  let(:user) { project.creator }

  before do
    stub_application_setting(auto_devops_enabled: false)
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'shows the suggest pipeline widget and then allows dismissal correctly' do
    expect(page).to have_content('Are you adding technical debt or code vulnerabilities?')

    page.within '.mr-pipeline-suggest' do
      find('[data-testid="close"]').click
    end

    wait_for_requests

    expect(page).not_to have_content('Are you adding technical debt or code vulnerabilities?')

    # Reload so we know the user callout was registered
    visit page.current_url

    expect(page).not_to have_content('Are you adding technical debt or code vulnerabilities?')
  end

  it 'runs tour from start to finish ensuring all nudges are executed' do
    # nudge 1
    expect(page).to have_content('Are you adding technical debt or code vulnerabilities?')

    page.within '.mr-pipeline-suggest' do
      find('[data-testid="ok"]').click
    end

    wait_for_requests

    # nudge 2
    expect(page).to have_content('Choose Code Quality to add a pipeline that tests the quality of your code.')

    find('.js-gitlab-ci-yml-selector').click

    wait_for_requests

    within '.gitlab-ci-yml-selector' do
      find('.dropdown-input-field').set('Jekyll')
      find('.dropdown-content li', text: 'Jekyll').click
    end

    wait_for_requests

    expect(page).not_to have_content('Choose Code Quality to add a pipeline that tests the quality of your code.')
    # nudge 3
    expect(page).to have_content('The template is ready!')

    find('#commit-changes').click

    wait_for_requests

    # nudge 4
    expect(page).to have_content("That's it, well done!")
  end
end
