require 'spec_helper'

feature 'Hook logs' do
  given(:web_hook_log) { create(:web_hook_log, response_body: '<script>') }
  given(:project) { web_hook_log.web_hook.project }
  given(:user) { create(:user) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  scenario 'user reads log without getting XSS' do
    visit(
      project_hook_hook_log_path(
        project, web_hook_log.web_hook, web_hook_log))

    expect(page).to have_content('<script>')
  end
end
