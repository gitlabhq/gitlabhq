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
    click_button 'Email a new issue to this project'

    page.within '#issuable-email-modal' do
      previous_token = page.find('input[type="text"]').value
      find('[data-testid="reset_email_token_link"]').click

      wait_for_requests

      expect(page.find('input[type="text"]').value).not_to eq previous_token
      new_token = project.new_issuable_address(user.reload, 'issue')
      expect(page.find('input[type="text"]').value).to eq new_token
    end
  end
end
