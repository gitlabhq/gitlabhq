require 'spec_helper'

feature 'Admin::HookLogs' do
  let(:project) { create(:project) }
  let(:system_hook) { create(:system_hook) }
  let(:hook_log) { create(:web_hook_log, web_hook: system_hook, internal_error_message: 'some error') }

  before do
    sign_in(create(:admin))
  end

  scenario 'show list of hook logs' do
    hook_log
    visit edit_admin_hook_path(system_hook)

    expect(page).to have_content('Recent Deliveries')
    expect(page).to have_content(hook_log.url)
  end

  scenario 'show hook log details' do
    hook_log
    visit edit_admin_hook_path(system_hook)
    click_link 'View details'

    expect(page).to have_content("POST #{hook_log.url}")
    expect(page).to have_content(hook_log.internal_error_message)
    expect(page).to have_content('Resend Request')
  end

  scenario 'retry hook log' do
    WebMock.stub_request(:post, system_hook.url)

    hook_log
    visit edit_admin_hook_path(system_hook)
    click_link 'View details'
    click_link 'Resend Request'

    expect(current_path).to eq(edit_admin_hook_path(system_hook))
  end
end
