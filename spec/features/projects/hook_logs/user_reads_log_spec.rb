# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Hook logs', feature_category: :webhooks do
  let(:project) { create(:project) }
  let(:project_hook) { create(:project_hook, project: project) }
  let(:web_hook_log) { create(:web_hook_log, web_hook: project_hook, response_body: 'Hello World') }
  let(:user) { create(:user) }

  before do
    web_hook_log
    project.add_maintainer(user)

    sign_in(user)
  end

  it 'shows list of hook logs' do
    visit edit_project_hook_path(project, project_hook)

    expect(page).to have_content('Recent events')
    expect(page).to have_link('View details', href: project_hook_hook_log_path(project, project_hook, web_hook_log))
  end

  it 'shows hook log details' do
    visit edit_project_hook_path(project, project_hook)
    click_link 'View details'

    expect(page).to have_content("POST #{web_hook_log.url}")
    expect(page).to have_content(web_hook_log.response_body)
    expect(page).to have_content('Resend Request')
  end

  it 'retries hook log' do
    WebMock.stub_request(:post, project_hook.url)

    visit edit_project_hook_path(project, project_hook)
    click_link 'View details'
    click_link 'Resend Request'

    expect(page).to have_current_path(edit_project_hook_path(project, project_hook), ignore_query: true)
  end

  context 'request gets internal error' do
    let(:web_hook_log) { create(:web_hook_log, web_hook: project_hook, internal_error_message: 'Some error') }

    it 'shows hook log details with internal error message' do
      visit edit_project_hook_path(project, project_hook)
      click_link 'View details'

      expect(page).to have_content("POST #{web_hook_log.url}")
      expect(page).to have_content(web_hook_log.internal_error_message)
      expect(page).to have_content('Resend Request')
    end
  end

  context 'response body contains XSS string' do
    let(:web_hook_log) { create(:web_hook_log, web_hook: project_hook, response_body: '<script>') }

    it 'displays log without getting XSS' do
      visit(project_hook_hook_log_path(project, project_hook, web_hook_log))

      expect(page).to have_content('<script>')
    end
  end

  context 'response data is too large' do
    let(:web_hook_log) do
      create(:web_hook_log, web_hook: project_hook, request_data: WebHookLog::OVERSIZE_REQUEST_DATA)
    end

    it 'shows request data as too large and disables retry function' do
      visit(project_hook_hook_log_path(project, project_hook, web_hook_log))

      expect(page).to have_content('Request data is too large')
      expect(page).not_to have_button(
        _('Resent request'),
        disabled: true, class: 'has-tooltip', title: _("Request data is too large")
      )
    end
  end
end
