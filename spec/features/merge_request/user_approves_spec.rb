# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User approves', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  it 'approves merge request' do
    visit project_merge_request_path(project, merge_request)
    click_approval_button('Approve')
    expect(page).to have_content('Approved by you')

    visit(project_merge_requests_path(project, state: :all))
    expect(page).to have_selector('[data-testid="mr-approvals"][aria-label="1 approval"]')

    visit project_merge_request_path(project, merge_request)
    click_approval_button('Revoke approval')
    expect(page).to have_content('Approval is optional')
  end

  def click_approval_button(action)
    page.within('.mr-state-widget') do
      click_button(action)
    end
  end
end
