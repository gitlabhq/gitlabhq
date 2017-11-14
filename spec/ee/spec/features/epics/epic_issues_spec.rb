require 'spec_helper'

describe 'Epic Issues', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:public_project) { create(:project, :public, group: group) }
  let(:private_project) { create(:project, :private, group: group) }
  let(:public_issue) { create(:issue, project: public_project) }
  let(:private_issue) { create(:issue, project: private_project) }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: public_issue),
      create(:epic_issue, epic: epic, issue: private_issue)
    ]
  end

  def visit_epic
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
        expect(page).not_to have_selector('button.js-issue-token-remove-button')
      end
    end

    it 'user cannot add new issues to the epic' do
      expect(page).not_to have_selector('.related-issues-block h3.panel-title button')
    end
  end

  context 'when user is a group member' do
    before do
      group.add_developer(user)
      visit_epic
    end

    it 'user can see all issues of the group and delete the associations' do
      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 2)
        expect(page).to have_content(public_issue.title)
        expect(page).to have_content(private_issue.title)

        first('li button.js-issue-token-remove-button').click
      end

      wait_for_requests

      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 1)
      end
    end

    it 'user can add new issues to the epic' do
      issue_to_add = create(:issue, project: private_project)
      issue_invalid = create(:issue)
      references = "#{issue_to_add.to_reference(full: true)} #{issue_invalid.to_reference(full: true)}"

      find('.related-issues-block h3.panel-title button').click
      find('.js-add-issuable-form-input').set references
      find('.js-add-issuable-form-add-button').click

      wait_for_requests

      within('.related-issues-block ul.issuable-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(issue_to_add.title)
      end
    end
  end
end
