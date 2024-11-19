# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Discussion Lock', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:project) { create(:project, :public) }
  let(:more_dropdown) { find_by_testid('desktop-dropdown') }
  let(:issuable_lock) { find_by_testid('issuable-lock') }
  let(:locked_badge) { '[data-testid="locked-badge"]' }
  let(:issuable_note_warning) { '[data-testid="issuable-note-warning"]' }

  before do
    sign_in(user)
  end

  context 'when a user is a team member' do
    before do
      project.add_developer(user)
    end

    context 'when the discussion is unlocked' do
      it 'the user can lock the issue' do
        visit project_issue_path(project, issue)

        more_dropdown.click
        expect(issuable_lock).to have_content('Lock discussion')

        issuable_lock.click
        expect(find('#notes')).to have_content('locked the discussion in this issue')
      end
    end

    context 'when the discussion is locked' do
      before do
        issue.update_attribute(:discussion_locked, true)
        visit project_issue_path(project, issue)
      end

      it 'the user can unlock the issue' do
        more_dropdown.click
        expect(issuable_lock).to have_content('Unlock discussion')

        issuable_lock.click
        expect(find('#notes')).to have_content('unlocked the discussion in this issue')
        expect(issuable_lock).to have_content('Lock discussion')
      end

      it 'the user can create a comment' do
        page.within('#notes .js-main-target-form') do
          fill_in 'note[note]', with: 'Some new comment'
          click_button 'Comment'
        end

        wait_for_requests

        expect(find('div#notes')).to have_content('Some new comment')
      end
    end
  end

  context 'when a user is not a team member' do
    context 'when the discussion is unlocked' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'the user can not lock the issue' do
        more_dropdown.click
        expect(issuable_lock).to have_content('Lock discussion')
      end

      it 'the user can create a comment' do
        page.within('#notes .js-main-target-form') do
          fill_in 'note[note]', with: 'Some new comment'
          click_button 'Comment'
        end

        wait_for_requests

        expect(find('div#notes')).to have_content('Some new comment')
      end
    end

    context 'when the discussion is locked' do
      before do
        issue.update_attribute(:discussion_locked, true)
        visit project_issue_path(project, issue)
      end

      it 'the user can not unlock the issue' do
        more_dropdown.click
        expect(issuable_lock).to have_content('Unlock discussion')
      end

      it 'the user can not create a comment' do
        page.within('#notes') do
          expect(page).not_to have_selector('js-main-target-form')
          expect(find_by_testid('disabled-comments'))
            .to have_content('The discussion in this issue is locked. Only project members can comment.')
        end
      end
    end
  end

  it 'passes axe automated accessibility testing' do
    project.add_developer(user)
    issue.update_attribute(:discussion_locked, true)
    visit project_issue_path(project, issue)
    wait_for_all_requests

    expect(page).to be_axe_clean.within(locked_badge)
    expect(page).to be_axe_clean.within(issuable_note_warning)

    more_dropdown.click
    expect(page).to be_axe_clean.within('[data-testid="lock-issue-toggle"] button')
  end
end
