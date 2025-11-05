# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items > User resets their incoming email token', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    stub_feature_flags(work_item_planning_view: true)
    stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
    sign_in(user)

    visit project_work_items_path(project)
  end

  it 'changes incoming email address token', :js do
    find_by_testid('work-items-list-more-actions-dropdown').click

    click_button 'Email work item to this project'

    page.within '#work-item-email-modal' do
      previous_token = page.find('input[type="text"]').value
      find_by_testid('reset_email_token_link').click

      wait_for_requests

      expect(page.find('input[type="text"]').value).not_to eq previous_token
      new_token = project.new_issuable_address(user.reload, 'issue')
      expect(page.find('input[type="text"]').value).to eq new_token
    end
  end
end
