# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::HookLogs', feature_category: :webhooks do
  let_it_be(:system_hook) { create(:system_hook) }
  let_it_be(:hook_log) { create(:web_hook_log, web_hook: system_hook, internal_error_message: 'some error') }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  it 'show list of hook logs' do
    hook_log
    visit edit_admin_hook_path(system_hook)

    expect(page).to have_content('Recent events')
    expect(page).to have_link('View details', href: admin_hook_hook_log_path(system_hook, hook_log))
  end

  it 'show hook log details' do
    hook_log
    visit edit_admin_hook_path(system_hook)
    click_link 'View details'

    expect(page).to have_content("POST #{hook_log.url}")
    expect(page).to have_content(hook_log.internal_error_message)
    expect(page).to have_content('Resend Request')
  end

  it 'retry hook log' do
    WebMock.stub_request(:post, system_hook.url)

    hook_log
    visit edit_admin_hook_path(system_hook)
    click_link 'View details'
    click_link 'Resend Request'

    expect(page).to have_current_path(edit_admin_hook_path(system_hook), ignore_query: true)
  end

  context 'response data is too large' do
    let(:hook_log) { create(:web_hook_log, web_hook: system_hook, request_data: WebHookLog::OVERSIZE_REQUEST_DATA) }

    it 'shows request data as too large and disables retry function' do
      visit(admin_hook_hook_log_path(system_hook, hook_log))

      expect(page).to have_content('Request data is too large')
      expect(page).not_to have_button(
        _('Resent request'),
        disabled: true, class: 'has-tooltip', title: _("Request data is too large")
      )
    end
  end
end
