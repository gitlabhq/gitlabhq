# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Related issues', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo, :public) }
  let(:project_b) { create(:project_empty_repo, :public) }
  let(:project_unauthorized) { create(:project_empty_repo, :public) }
  let(:issue_a) { create(:issue, project: project) }
  let(:issue_b) { create(:issue, project: project) }
  let(:issue_c) { create(:issue, project: project) }
  let(:issue_d) { create(:issue, project: project) }
  let(:issue_project_b_a) { create(:issue, project: project_b) }
  let(:issue_project_unauthorized_a) { create(:issue, project: project_unauthorized) }

  context 'widget visibility' do
    context 'when not logged in' do
      it 'does not show widget when internal project' do
        project = create :project_empty_repo, :internal
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'does not show widget when private project' do
        project = create :project_empty_repo, :private
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'shows widget when public project' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end
    end

    context 'when logged in but not a member' do
      before do
        gitlab_sign_in(user)
      end

      it 'shows widget when internal project' do
        project = create :project_empty_repo, :internal
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end

      it 'does not show widget when private project' do
        project = create :project_empty_repo, :private
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'shows widget when public project' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget on their own public issue' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project, author: user

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end
    end

    context 'when logged in and a guest' do
      before do
        gitlab_sign_in(user)
      end

      it 'shows widget when internal project' do
        project = create :project_empty_repo, :internal
        issue = create :issue, project: project
        project.add_guest(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget when private project' do
        project = create :project_empty_repo, :private
        issue = create :issue, project: project
        project.add_guest(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget when public project' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project
        project.add_guest(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_selector('.js-issue-count-badge-add-button')
      end
    end

    context 'when logged in and a reporter' do
      before do
        gitlab_sign_in(user)
      end

      it 'shows widget when internal project' do
        project = create :project_empty_repo, :internal
        issue = create :issue, project: project
        project.add_reporter(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget when private project' do
        project = create :project_empty_repo, :private
        issue = create :issue, project: project
        project.add_reporter(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget when public project' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project
        project.add_reporter(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_selector('.js-issue-count-badge-add-button')
      end

      it 'shows widget on their own public issue' do
        project = create :project_empty_repo, :public
        issue = create :issue, project: project, author: user
        project.add_reporter(user)

        visit project_issue_path(project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_selector('.js-issue-count-badge-add-button')
      end
    end
  end

  context 'when user has no permission to manage related issues' do
    let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
    let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

    before do
      project.add_guest(user)
      gitlab_sign_in(user)
    end

    context 'visiting some issue someone else created' do
      before do
        visit project_issue_path(project, issue_a)
        wait_for_requests
      end

      it 'shows related issues count' do
        expect(find('.js-related-issues-header-issue-count')).to have_content('2')
      end
    end

    context 'visiting issue_b which was targeted by issue_a' do
      before do
        visit project_issue_path(project, issue_b)
        wait_for_requests
      end

      it 'shows related issues count' do
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end
    end
  end

  context 'when user has permission to manage related issues' do
    before do
      project.add_maintainer(user)
      project_b.add_maintainer(user)
      gitlab_sign_in(user)
    end

    context 'without existing related issues' do
      before do
        visit project_issue_path(project, issue_a)
        wait_for_requests
      end

      it 'shows related issues count' do
        expect(find('.js-related-issues-header-issue-count')).to have_content('0')
      end

      it 'add related issue' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "#{issue_b.to_reference(project)} "
        find('.js-add-issuable-form-add-button').click

        wait_for_requests

        items = all('.item-title a')

        # Form gets hidden after submission
        expect(page).not_to have_selector('.js-add-related-issues-form-area')
        # Check if related issues are present
        expect(items.count).to eq(1)
        expect(items[0].text).to eq(issue_b.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end

      it 'add cross-project related issue' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "#{issue_project_b_a.to_reference(project)} "
        find('.js-add-issuable-form-add-button').click

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(1)
        expect(items[0].text).to eq(issue_project_b_a.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end

      it 'pressing enter should submit the form' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "#{issue_project_b_a.to_reference(project)} "
        find('.js-add-issuable-form-input').native.send_key(:enter)

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(1)
        expect(items[0].text).to eq(issue_project_b_a.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end

      it 'disallows duplicate entries' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set 'duplicate duplicate duplicate'

        items = all('.js-add-issuable-form-token-list-item')
        expect(items.count).to eq(1)
        expect(items[0].text).to eq('duplicate')

        # Pending issues aren't counted towards the related issue count
        expect(find('.js-related-issues-header-issue-count')).to have_content('0')
      end

      it 'allows us to remove pending issues' do
        # Tests against https://gitlab.com/gitlab-org/gitlab/issues/11625
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set 'issue1 issue2 issue3 '

        items = all('.js-add-issuable-form-token-list-item')
        expect(items.count).to eq(3)
        expect(items[0].text).to eq('issue1')
        expect(items[1].text).to eq('issue2')
        expect(items[2].text).to eq('issue3')

        # Remove pending issues left to right to make sure none get stuck
        items[0].find('.js-issue-token-remove-button').click
        items = all('.js-add-issuable-form-token-list-item')
        expect(items.count).to eq(2)
        expect(items[0].text).to eq('issue2')
        expect(items[1].text).to eq('issue3')

        items[0].find('.js-issue-token-remove-button').click
        items = all('.js-add-issuable-form-token-list-item')
        expect(items.count).to eq(1)
        expect(items[0].text).to eq('issue3')

        items[0].find('.js-issue-token-remove-button').click
        items = all('.js-add-issuable-form-token-list-item')
        expect(items.count).to eq(0)
      end
    end

    context 'with existing related issues' do
      let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
      let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

      before do
        visit project_issue_path(project, issue_a)
        wait_for_requests
      end

      it 'shows related issues count' do
        expect(find('.js-related-issues-header-issue-count')).to have_content('2')
      end

      it 'shows related issues' do
        items = all('.item-title a')

        expect(items.count).to eq(2)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
      end

      it 'allows us to remove a related issues' do
        items_before = all('.item-title a')

        expect(items_before.count).to eq(2)

        first('.js-issue-item-remove-button').click

        wait_for_requests

        items_after = all('.item-title a')

        expect(items_after.count).to eq(1)
      end

      it 'add related issue' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "##{issue_d.iid} "
        find('.js-add-issuable-form-add-button').click

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(3)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
        expect(items[2].text).to eq(issue_d.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('3')
      end

      it 'add invalid related issue' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "#9999999 "
        find('.js-add-issuable-form-add-button').click

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(2)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('2')
      end

      it 'add unauthorized related issue' do
        find('.js-issue-count-badge-add-button').click
        find('.js-add-issuable-form-input').set "#{issue_project_unauthorized_a.to_reference(project)} "
        find('.js-add-issuable-form-add-button').click

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(2)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('2')
      end
    end
  end
end
