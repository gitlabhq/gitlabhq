require 'spec_helper'

describe 'Epic Issues', :js do
  include DragTo

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:public_project) { create(:project, :public, group: group) }
  let(:private_project) { create(:project, :private, group: group) }
  let(:public_issue) { create(:issue, project: public_project) }
  let(:private_issue) { create(:issue, project: private_project) }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: public_issue, relative_position: 1),
      create(:epic_issue, epic: epic, issue: private_issue, relative_position: 2)
    ]
  end

  def visit_epic
    stub_licensed_features(epics: true)

    sign_in(user)
    visit group_epic_path(group, epic)
    wait_for_requests
  end

  context 'when user is not a group member of a public group' do
    before do
      visit_epic
    end

    it 'user can see issues from public project but cannot delete the associations' do
      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 1)
        expect(page).to have_content(public_issue.title)
        expect(page).not_to have_selector('button.js-issue-item-remove-button')
      end
    end

    it 'user cannot add new issues to the epic' do
      expect(page).not_to have_selector('.related-issues-block h3.panel-title button')
    end

    it 'user cannot reorder issues in epic' do
      expect(page).not_to have_selector('.js-related-issues-token-list-item.user-can-drag')
    end
  end

  context 'when user is a group member' do
    let(:issue_to_add) { create(:issue, project: private_project) }
    let(:issue_invalid) { create(:issue) }

    def add_issues(references)
      find('.related-issues-block h3.panel-title button').click
      find('.js-add-issuable-form-input').set(references)
      find('.js-add-issuable-form-add-button').click

      wait_for_requests
    end

    before do
      group.add_developer(user)
      visit_epic
    end

    it 'user can see all issues of the group and delete the associations' do
      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 2)
        expect(page).to have_content(public_issue.title)
        expect(page).to have_content(private_issue.title)

        first('li button.js-issue-item-remove-button').click
      end

      wait_for_requests

      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 1)
      end
    end

    it 'user cannot add new issues to the epic from another group' do
      add_issues("#{issue_invalid.to_reference(full: true)}")

      expect(page).to have_selector('.content-wrapper .alert-wrapper .flash-text')
      expect(find('.flash-alert')).to have_text('No Issue found for given params')
    end

    it 'user can add new issues to the epic' do
      references = "#{issue_to_add.to_reference(full: true)} #{issue_invalid.to_reference(full: true)}"

      add_issues(references)

      expect(page).not_to have_selector('.content-wrapper .alert-wrapper .flash-text')
      expect(page).not_to have_content('No Issue found for given params')

      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(issue_to_add.title)
      end
    end

    it 'user can reorder issues in epic' do
      expect(first('.js-related-issues-token-list-item')).to have_content(public_issue.title)
      expect(page.all('.js-related-issues-token-list-item').last).to have_content(private_issue.title)

      drag_to(selector: '.issuable-list', to_index: 1)

      expect(first('.js-related-issues-token-list-item')).to have_content(private_issue.title)
      expect(page.all('.js-related-issues-token-list-item').last).to have_content(public_issue.title)
    end
  end
end
