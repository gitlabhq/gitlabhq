# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User approves', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'approves merge request' do
    click_approval_button('Approve')
    expect(page).to have_content('Approved by you')

    verify_approvals_count_on_index!

    click_approval_button('Revoke approval')
    expect(page).to have_content('Approval is optional')
  end

  def verify_approvals_count_on_index!
    visit(project_merge_requests_path(project, state: :all))
    expect(
      page.all('[data-testid="mr-appovals"]').any? do |item|
        item["aria-label"] == "1 approval"
      end
    ).to be true
    visit project_merge_request_path(project, merge_request)
  end

  def click_approval_button(action)
    page.within('.mr-state-widget') do
      click_button(action)
    end

    wait_for_requests
  end
end
