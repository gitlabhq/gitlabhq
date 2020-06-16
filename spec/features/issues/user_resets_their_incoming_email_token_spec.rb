# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User resets their incoming email token' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
    project.add_maintainer(user)
    sign_in(user)

    visit namespace_project_issues_path(user.namespace, project)
  end

  it 'changes incoming email address token', :js do
    find('.issuable-email-modal-btn').click
    previous_token = find('input#issuable_email').value
    find('.incoming-email-token-reset').click

    wait_for_requests

    expect(page).to have_no_field('issuable_email', with: previous_token)
    new_token = project.new_issuable_address(user.reload, 'issue')
    expect(page).to have_field(
      'issuable_email',
      with: new_token
    )
  end
end
