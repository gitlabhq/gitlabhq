# frozen_string_literal: true

require 'spec_helper'

describe 'Hook logs' do
  let(:web_hook_log) { create(:web_hook_log, response_body: '<script>') }
  let(:project) { web_hook_log.web_hook.project }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  it 'user reads log without getting XSS' do
    visit(
      project_hook_hook_log_path(
        project, web_hook_log.web_hook, web_hook_log))

    expect(page).to have_content('<script>')
  end
end
