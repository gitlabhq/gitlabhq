# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User resets their incoming email token', feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(work_item_view_for_issues: true)

    stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
    project.add_maintainer(user)
    sign_in(user)

    visit namespace_project_issues_path(user.namespace, project)
  end

  it 'changes incoming email address token', :js do
    click_button 'Email a new work item to this project'

    within_modal do
      previous_token = page.find('input[type="text"]').value
      find_by_testid('reset_email_token_link').click

      wait_for_requests

      expect(page.find('input[type="text"]').value).not_to eq previous_token
      new_token = project.new_issuable_address(user.reload, 'issue')
      expect(page.find('input[type="text"]').value).to eq new_token
    end
  end
end
