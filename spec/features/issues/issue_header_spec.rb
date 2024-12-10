# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue header', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:closed_issue) { create(:issue, :closed, project: project) }
  let_it_be(:closed_locked_issue) { create(:issue, :closed, :locked, project: project) }
  let_it_be(:authored_issue) { create(:issue, project: project, author: user) }
  let_it_be(:confidential_issue) { create(:issue, :confidential, project: project) }

  context 'when user has permission to update' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'within the issue actions dropdown menu' do
      before do
        visit project_issue_path(project, issue)

        # Click on the ellipsis icon
        click_button 'Issue actions'
      end

      it 'shows the "New related issue", "Report abuse", and "Delete issue" items', :aggregate_failures do
        expect(page).to have_link 'New related issue'
        expect(page).to have_button 'Report abuse'
        expect(page).to have_button 'Delete issue'
        expect(page).not_to have_link 'Submit as spam'
      end
    end

    context 'when the issue is open' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'has a "Close issue" button' do
        expect(page).to have_button 'Close issue'
      end
    end

    context 'when the issue is closed' do
      before do
        visit project_issue_path(project, closed_issue)
      end

      it 'has a "Reopen issue" button' do
        expect(page).to have_button 'Reopen issue'
      end
    end

    context 'when the issue is closed and locked' do
      before do
        visit project_issue_path(project, closed_locked_issue)
      end

      it 'does not have a "Reopen issue" button' do
        expect(page).not_to have_button 'Reopen issue'
      end
    end

    context 'when the current user is the issue author' do
      before do
        visit project_issue_path(project, authored_issue)
      end

      it 'does not show "Report abuse" button in dropdown' do
        click_button 'Issue actions'

        expect(page).not_to have_button 'Report abuse'
      end
    end

    context 'when the issue is not confidential' do
      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      it 'shows "Turn on confidentiality" button in dropdown' do
        click_button 'Issue actions'

        expect(page).to have_button 'Turn on confidentiality'
      end
    end

    context 'when the issue is confidential' do
      before do
        visit project_issue_path(project, confidential_issue)
        wait_for_requests
      end

      it 'shows "Turn off confidentiality" button in dropdown' do
        click_button 'Issue actions'

        expect(page).to have_button 'Turn off confidentiality'
      end
    end
  end

  context 'when user is admin and the project is set up for spam' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user_agent_detail) { create(:user_agent_detail, subject: issue) }

    before do
      stub_application_setting(akismet_enabled: true)
      project.add_maintainer(admin)
      sign_in(admin)
    end

    context 'within the issue actions dropdown menu' do
      before do
        visit project_issue_path(project, issue)

        # Click on the ellipsis icon
        click_button 'Issue actions'
      end

      it 'has "Submit as spam" item' do
        expect(page).to have_link 'Submit as spam'
      end
    end
  end

  context 'when user does not have permission to update' do
    before do
      project.add_guest(user)
      sign_in(user)
    end

    context 'within the issue actions dropdown menu' do
      before do
        visit project_issue_path(project, issue)

        # Click on the ellipsis icon
        click_button 'Issue actions'
      end

      it 'only shows the "New related issue" and "Report abuse" items', :aggregate_failures do
        expect(page).to have_link 'New related issue'
        expect(page).to have_button 'Report abuse'
        expect(page).not_to have_link 'Submit as spam'
        expect(page).not_to have_button 'Delete issue'
        expect(page).not_to have_button 'Turn on confidentiality'
      end
    end

    context 'when the issue is open' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'does not have a "Close issue" button' do
        expect(page).not_to have_button 'Close issue'
      end
    end

    context 'when the issue is closed' do
      before do
        visit project_issue_path(project, closed_issue)
      end

      it 'does not have a "Reopen issue" button' do
        expect(page).not_to have_button 'Reopen issue'
      end
    end

    context 'when the issue is closed and locked' do
      before do
        visit project_issue_path(project, closed_locked_issue)
      end

      it 'does not have a "Reopen issue" button' do
        expect(page).not_to have_button 'Reopen issue'
      end
    end

    context 'when the current user is the issue author' do
      before do
        visit project_issue_path(project, authored_issue)
      end

      it 'does not show "Report abuse" button in dropdown' do
        click_button 'Issue actions'

        expect(page).not_to have_button 'Report abuse'
      end
    end
  end
end
