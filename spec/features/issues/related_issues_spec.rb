# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Related issues', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:project_b) { create(:project_empty_repo, :public) }
  let_it_be(:project_unauthorized) { create(:project_empty_repo, :public) }
  let_it_be(:internal_project) { create(:project_empty_repo, :internal) }
  let_it_be(:private_project) { create(:project_empty_repo, :private) }
  let_it_be(:public_project) { create(:project_empty_repo, :public) }

  let_it_be(:issue_a) { create(:issue, project: project) }
  let_it_be(:issue_b) { create(:issue, project: project) }
  let_it_be(:issue_c) { create(:issue, project: project) }
  let_it_be(:issue_d) { create(:issue, project: project) }
  let_it_be(:issue_project_b_a) { create(:issue, project: project_b) }
  let_it_be(:issue_project_unauthorized_a) { create(:issue, project: project_unauthorized) }
  let_it_be(:internal_issue) { create(:issue, project: internal_project) }
  let_it_be(:private_issue) { create(:issue, project: private_project) }
  let_it_be(:public_issue) { create(:issue, project: public_project) }

  context 'widget visibility' do
    context 'when not logged in' do
      it 'does not show widget when internal project' do
        visit project_issue_path(internal_project, internal_issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'does not show widget when private project' do
        visit project_issue_path(private_project, private_issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'shows widget when public project' do
        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end
    end

    context 'when logged in but not a member' do
      before do
        sign_in(user)
      end

      it 'shows widget when internal project' do
        visit project_issue_path(internal_project, internal_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end

      it 'does not show widget when private project' do
        visit project_issue_path(private_project, private_issue)

        expect(page).not_to have_css('.related-issues-block')
      end

      it 'shows widget when public project' do
        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end

      it 'shows widget on their own public issue' do
        issue = create :issue, project: public_project, author: user

        visit project_issue_path(public_project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end
    end

    context 'when logged in and a guest' do
      before do
        sign_in(user)
      end

      it 'shows widget when internal project' do
        internal_project.add_guest(user)

        visit project_issue_path(internal_project, internal_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end

      it 'shows widget when private project' do
        private_project.add_guest(user)

        visit project_issue_path(private_project, private_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end

      it 'shows widget when public project' do
        public_project.add_guest(user)

        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).not_to have_button 'Add a related issue'
      end
    end

    context 'when logged in and a reporter' do
      before do
        sign_in(user)
      end

      it 'shows widget when internal project' do
        internal_project.add_reporter(user)

        visit project_issue_path(internal_project, internal_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_button 'Add a related issue'
      end

      it 'shows widget when private project' do
        private_project.add_reporter(user)

        visit project_issue_path(private_project, private_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_button 'Add a related issue'
      end

      it 'shows widget when public project' do
        public_project.add_reporter(user)

        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_button 'Add a related issue'
      end

      it 'shows widget on their own public issue' do
        issue = create :issue, project: public_project, author: user
        public_project.add_reporter(user)

        visit project_issue_path(public_project, issue)

        expect(page).to have_css('.related-issues-block')
        expect(page).to have_button 'Add a related issue'
      end
    end
  end

  context 'when user has no permission to manage related issues' do
    let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
    let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

    before_all do
      project.add_guest(user)
    end

    before do
      sign_in(user)
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
    before_all do
      project.add_maintainer(user)
      project_b.add_maintainer(user)
    end

    before do
      sign_in(user)
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
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "#{issue_b.to_reference(project)} "
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

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
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "#{issue_project_b_a.to_reference(project)} "
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(1)
        expect(items[0].text).to eq(issue_project_b_a.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end

      it 'pressing enter should submit the form' do
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "#{issue_project_b_a.to_reference(project)} "
        find_field('Paste issue link').native.send_key(:enter)

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(1)
        expect(items[0].text).to eq(issue_project_b_a.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('1')
      end

      it 'disallows duplicate entries' do
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: 'duplicate duplicate duplicate'

        items = all('.issue-token')
        expect(items.count).to eq(1)
        expect(items[0].text).to eq('duplicate')

        # Pending issues aren't counted towards the related issue count
        expect(find('.js-related-issues-header-issue-count')).to have_content('0')
      end

      it 'allows us to remove pending issues' do
        # Tests against https://gitlab.com/gitlab-org/gitlab/issues/11625
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: 'issue1 issue2 issue3 '

        items = all('.issue-token')
        expect(items.count).to eq(3)
        expect(items[0].text).to eq('issue1')
        expect(items[1].text).to eq('issue2')
        expect(items[2].text).to eq('issue3')

        # Remove pending issues left to right to make sure none get stuck
        within items[0] do
          click_button 'Remove'
        end
        items = all('.issue-token')
        expect(items.count).to eq(2)
        expect(items[0].text).to eq('issue2')
        expect(items[1].text).to eq('issue3')

        within items[0] do
          click_button 'Remove'
        end
        items = all('.issue-token')
        expect(items.count).to eq(1)
        expect(items[0].text).to eq('issue3')

        within items[0] do
          click_button 'Remove'
        end
        items = all('.issue-token')
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
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "##{issue_d.iid} "
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(3)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
        expect(items[2].text).to eq(issue_d.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('3')
      end

      it 'add invalid related issue' do
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: '#9999999 '
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

        wait_for_requests

        items = all('.item-title a')

        expect(items.count).to eq(2)
        expect(items[0].text).to eq(issue_b.title)
        expect(items[1].text).to eq(issue_c.title)
        expect(find('.js-related-issues-header-issue-count')).to have_content('2')
      end

      it 'add unauthorized related issue' do
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "#{issue_project_unauthorized_a.to_reference(project)} "
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

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
