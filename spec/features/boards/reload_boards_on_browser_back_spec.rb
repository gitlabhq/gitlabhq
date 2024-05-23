# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ensure Boards do not show stale data on browser back', :js, feature_category: :portfolio_management do
  let(:project) { create(:project, :public) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }

  context 'authorized user' do
    before do
      project.add_maintainer(user)

      sign_in(user)

      visit project_board_path(project, board)
      wait_for_requests

      page.within(first('.board [data-testid="issue-count-badge"]')) do
        expect(page).to have_content('0')
      end
    end

    it 'created issue is listed on board' do
      visit new_project_issue_path(project)
      wait_for_requests

      fill_in 'issue_title', with: 'issue should be shown'

      click_button 'Create issue'

      page.go_back
      wait_for_requests

      page.go_back
      wait_for_requests

      page.within(first('.board [data-testid="issue-count-badge"]')) do
        expect(page).to have_content('1')
      end

      page.within(first('.board-card')) do
        issue = project.issues.find_by_title('issue should be shown')

        expect(page).to have_content(issue.to_reference)
        expect(page).to have_link(issue.title, href: /#{issue_path(issue)}/)
      end
    end
  end
end
