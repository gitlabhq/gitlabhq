# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views an SVG design that contains XSS', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:file) { Rails.root.join('spec', 'fixtures', 'logo_sample.svg') }
  let(:design) { create(:design, :with_file, filename: 'xss.svg', file: file, issue: issue) }

  before do
    enable_design_management

    visit designs_project_issue_path(
      project,
      issue,
      { vueroute: design.filename }
    )

    wait_for_requests
  end

  it 'has XSS within the SVG file' do
    file_content = File.read(file)

    expect(file_content).to include("<script>alert('FAIL')</script>")
  end

  it 'displays the SVG', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/381115' do
    find_by_testid('close-design').click
    expect(page).to have_selector("img.design-img[alt='xss.svg']", count: 1, visible: false)
  end

  it 'does not execute the JavaScript within the SVG' do
    # The expectation is that we can call the capybara `page.dismiss_prompt`
    # method to close a JavaScript alert prompt without a `Capybara::ModalNotFound`
    # being raised.
    run_expectation = -> {
      page.dismiss_prompt(wait: 1)
    }

    # With the page loaded, there should be no alert modal
    expect { run_expectation.call }.to raise_error(
      Capybara::ModalNotFound,
      'Unable to find modal dialog'
    )

    # Perform a negative control test of the above expectation.
    # With an alert modal displaying, the modal should be dismissable.
    execute_script('alert(true)')

    expect { run_expectation.call }.not_to raise_error
  end
end
