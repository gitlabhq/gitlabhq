require 'rails_helper'

feature 'Merge request issue assignment', js: true, feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue1) { create(:issue, project: project) }
  let(:issue2) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user, description: "fixes #{issue1.to_reference} and #{issue2.to_reference}") }
  let(:service) { MergeRequests::AssignIssuesService.new(merge_request, user, user, project) }

  before do
    project.team << [user, :developer]
  end

  def visit_merge_request(current_user = nil)
    sign_in(current_user || user)
    visit project_merge_request_path(project, merge_request)
  end

  context 'logged in as author' do
    it 'updates related issues' do
      visit_merge_request
      click_link "Assign yourself to these issues"

      expect(page).to have_content "2 issues have been assigned to you"
    end

    it 'returns user to the merge request' do
      visit_merge_request
      click_link "Assign yourself to these issues"

      expect(page).to have_content merge_request.description
    end

    it "doesn't display if related issues are already assigned" do
      [issue1, issue2].each { |issue| issue.update!(assignees: [user]) }

      visit_merge_request

      expect(page).not_to have_content "Assign yourself"
    end
  end

  context 'not MR author' do
    it "doesn't not show assignment link" do
      visit_merge_request(create(:user))

      expect(page).not_to have_content "Assign yourself"
    end
  end
end
