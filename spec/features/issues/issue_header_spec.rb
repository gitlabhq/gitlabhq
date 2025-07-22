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

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'when user has permission to update' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'within the issue actions dropdown menu' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'shows the "New related item", "Report abuse", and "Delete issue" items', :aggregate_failures do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).to have_button 'New related item'
          expect(page).to have_button 'Report abuse'
          expect(page).to have_button 'Delete issue'
          expect(page).not_to have_link 'Submit as spam'
        end
      end
    end

    context 'when the issue is closed and locked' do
      before do
        visit project_issue_path(project, closed_locked_issue)
      end

      it 'does not have a "Reopen issue" button' do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).not_to have_button 'Reopen issue'
        end
      end
    end

    context 'when the current user is the issue author' do
      before do
        visit project_issue_path(project, authored_issue)
      end

      it 'does not show "Report abuse" button in dropdown' do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).not_to have_button 'Report abuse'
        end
      end
    end

    context 'when the issue is not confidential' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'shows "Turn on confidentiality" button in dropdown' do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).to have_button 'Turn on confidentiality'
        end
      end
    end

    context 'when the issue is confidential' do
      before do
        visit project_issue_path(project, confidential_issue)
      end

      it 'shows "Turn off confidentiality" button in dropdown' do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).to have_button 'Turn off confidentiality'
        end
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
      end

      it 'has "Submit as spam" item' do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).to have_link 'Submit as spam'
        end
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
      end

      it 'only shows the "Report abuse" items', :aggregate_failures do
        within_testid('work-item-actions-dropdown') do
          click_button 'More actions'

          expect(page).to have_button 'Report abuse'
          expect(page).not_to have_button 'New related item'
          expect(page).not_to have_link 'Submit as spam'
          expect(page).not_to have_button 'Delete issue'
          expect(page).not_to have_button 'Turn on confidentiality'
        end
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
  end
end
