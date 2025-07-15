# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussion Lock', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:project) { create(:project, :public) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    sign_in(user)
  end

  context 'when a user is a team member' do
    before do
      project.add_developer(user)
    end

    context 'when the discussion is unlocked' do
      it 'the user can lock and unlock the issue' do
        visit project_issue_path(project, issue)

        click_button 'More actions', match: :first
        click_button 'Lock discussion'

        expect(page).to have_text('locked the discussion in this work item')
        expect(page).to have_text('Discussion is locked. Only members can comment.')

        click_button 'More actions', match: :first
        click_button 'Unlock discussion'

        expect(page).to have_text('unlocked the discussion in this work item')
        expect(page).not_to have_text('Discussion is locked. Only members can comment.')
      end
    end

    context 'when the discussion is locked' do
      before do
        issue.update_attribute(:discussion_locked, true)
        visit project_issue_path(project, issue)
      end

      it 'the user can create a comment' do
        fill_in 'Add a reply', with: 'Some new comment'
        click_button 'Comment'

        within('.work-item-notes') do
          expect(page).to have_text('Some new comment')
        end
      end
    end
  end

  context 'when a user is not a team member' do
    context 'when the discussion is unlocked' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'the user can not lock the issue but can create comment' do
        click_button 'More actions', match: :first

        expect(page).not_to have_button 'Lock discussion'

        fill_in 'Add a reply', with: 'Some new comment'
        click_button 'Comment'

        within('.work-item-notes') do
          expect(page).to have_text('Some new comment')
        end
      end
    end

    context 'when the discussion is locked' do
      before do
        issue.update_attribute(:discussion_locked, true)
        visit project_issue_path(project, issue)
      end

      it 'the user can not unlock the issue or create a comment' do
        click_button 'More actions', match: :first

        expect(page).not_to have_button 'Unlock discussion'
        expect(page).not_to have_field 'Add a reply'
        expect(page).to have_text('The discussion in this issue is locked. Only project members can comment.')
      end
    end
  end

  it 'passes axe automated accessibility testing' do
    project.add_developer(user)
    issue.update_attribute(:discussion_locked, true)
    visit project_issue_path(project, issue)

    expect(page).to be_axe_clean.within('[data-testid="locked-badge"]') # rubocop: disable Capybara/TestidFinders -- within_testid does not work here
    expect(page).to be_axe_clean.within('[data-testid="issuable-note-warning"]') # rubocop: disable Capybara/TestidFinders -- within_testid does not work here
  end
end
