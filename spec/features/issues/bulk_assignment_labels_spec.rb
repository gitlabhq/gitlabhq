require 'rails_helper'

feature 'Issues > Labels bulk assignment' do
  let(:user)      { create(:user) }
  let!(:project)  { create(:project) }
  let!(:issue1)   { create(:issue, project: project, title: "Issue 1") }
  let!(:issue2)   { create(:issue, project: project, title: "Issue 2") }
  let!(:bug)      { create(:label, project: project, title: 'bug') }
  let!(:feature)  { create(:label, project: project, title: 'feature') }
  let!(:wontfix)  { create(:label, project: project, title: 'wontfix') }

  context 'as an allowed user', :js do
    before do
      project.add_master(user)

      sign_in user
    end

    context 'sidebar' do
      before do
        enable_bulk_update
      end

      it 'is present when bulk edit is enabled' do
        expect(page).to have_css('.issuable-sidebar')
      end

      it 'is not present when bulk edit is disabled' do
        disable_bulk_update
        expect(page).not_to have_css('.issuable-sidebar')
      end
    end

    context 'can bulk assign' do
      before do
        enable_bulk_update
      end

      context 'a label' do
        context 'to all issues' do
          before do
            check 'check-all-issues'
            open_labels_dropdown ['bug']
            update_issues
          end

          it do
            expect(find("#issue_#{issue1.id}")).to have_content 'bug'
            expect(find("#issue_#{issue2.id}")).to have_content 'bug'
          end
        end

        context 'to a issue' do
          before do
            check "selected_issue_#{issue1.id}"
            open_labels_dropdown ['bug']
            update_issues
          end

          it do
            expect(find("#issue_#{issue1.id}")).to have_content 'bug'
            expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
          end
        end
      end

      context 'multiple labels' do
        context 'to all issues' do
          before do
            check 'check-all-issues'
            open_labels_dropdown %w(bug feature)
            update_issues
          end

          it do
            expect(find("#issue_#{issue1.id}")).to have_content 'bug'
            expect(find("#issue_#{issue1.id}")).to have_content 'feature'
            expect(find("#issue_#{issue2.id}")).to have_content 'bug'
            expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          end
        end

        context 'to a issue' do
          before do
            check "selected_issue_#{issue1.id}"
            open_labels_dropdown %w(bug feature)
            update_issues
          end

          it do
            expect(find("#issue_#{issue1.id}")).to have_content 'bug'
            expect(find("#issue_#{issue1.id}")).to have_content 'feature'
            expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
            expect(find("#issue_#{issue2.id}")).not_to have_content 'feature'
          end
        end
      end
    end

    context 'can assign a label to all issues when label is present' do
      before do
        issue2.labels << bug
        issue2.labels << feature

        enable_bulk_update
        check 'check-all-issues'

        open_labels_dropdown ['bug']
        update_issues
      end

      it do
        expect(find("#issue_#{issue1.id}")).to have_content 'bug'
        expect(find("#issue_#{issue2.id}")).to have_content 'bug'
      end
    end

    context 'can bulk un-assign' do
      context 'all labels to all issues' do
        before do
          issue1.labels << bug
          issue1.labels << feature
          issue2.labels << bug
          issue2.labels << feature

          enable_bulk_update
          check 'check-all-issues'
          unmark_labels_in_dropdown %w(bug feature)
          update_issues
        end

        it do
          expect(find("#issue_#{issue1.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).not_to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'feature'
        end
      end

      context 'a label to a issue' do
        before do
          issue1.labels << bug
          issue2.labels << feature

          enable_bulk_update
          check_issue issue1
          unmark_labels_in_dropdown ['bug']
          update_issues
        end

        it do
          expect(find("#issue_#{issue1.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
        end
      end

      context 'a label and keep the others label' do
        before do
          issue1.labels << bug
          issue1.labels << feature
          issue2.labels << bug
          issue2.labels << feature

          enable_bulk_update
          check_issue issue1
          check_issue issue2
          unmark_labels_in_dropdown ['bug']
          update_issues
        end

        it do
          expect(find("#issue_#{issue1.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
        end
      end
    end

    context 'toggling a milestone' do
      let!(:milestone) { create(:milestone, project: project, title: 'First Release') }

      context 'setting a milestone' do
        before do
          issue1.labels << bug
          issue2.labels << feature
          enable_bulk_update
        end

        it 'keeps labels' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'

          check 'check-all-issues'

          open_milestone_dropdown(['First Release'])
          update_issues

          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'First Release'
        end
      end

      context 'setting a milestone and adding another label' do
        before do
          issue1.labels << bug
          enable_bulk_update
        end

        it 'keeps existing label and new label is present' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'

          check 'check-all-issues'
          open_milestone_dropdown ['First Release']
          open_labels_dropdown ['feature']
          update_issues

          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'feature'
          expect(find("#issue_#{issue1.id}")).to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'First Release'
        end
      end

      context 'setting a milestone and removing existing label' do
        before do
          issue1.labels << bug
          issue1.labels << feature
          issue2.labels << feature

          enable_bulk_update
        end

        it 'keeps existing label and new label is present' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'

          check 'check-all-issues'

          open_milestone_dropdown ['First Release']
          unmark_labels_in_dropdown ['feature']
          update_issues

          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).not_to have_content 'feature'
          expect(find("#issue_#{issue1.id}")).to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'First Release'
        end
      end

      context 'unsetting a milestone' do
        before do
          issue1.milestone = milestone
          issue2.milestone = milestone
          issue1.save
          issue2.save
          issue1.labels << bug
          issue2.labels << feature

          enable_bulk_update
        end

        it 'keeps labels' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'First Release'

          check 'check-all-issues'
          open_milestone_dropdown(['No Milestone'])
          update_issues

          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).not_to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'First Release'
        end
      end
    end

    context 'toggling checked issues' do
      before do
        issue1.labels << bug
        enable_bulk_update
      end

      it do
        expect(find("#issue_#{issue1.id}")).to have_content 'bug'

        check_issue issue1
        open_labels_dropdown ['feature']
        uncheck_issue issue1
        check_issue issue1
        update_issues
        sleep 1 # needed

        expect(find("#issue_#{issue1.id}")).to have_content 'bug'
        expect(find("#issue_#{issue1.id}")).not_to have_content 'feature'
      end
    end

    # Special case https://gitlab.com/gitlab-org/gitlab-ce/issues/24877
    context 'unmarking common label' do
      before do
        issue1.labels << bug
        issue1.labels << feature
        issue2.labels << bug

        enable_bulk_update
      end

      it 'applies label from filtered results' do
        check 'check-all-issues'

        page.within('.issues-bulk-update') do
          click_button 'Select labels'
          wait_for_requests

          expect(find('.dropdown-menu-labels li', text: 'bug')).to have_css('.is-active')
          expect(find('.dropdown-menu-labels li', text: 'feature')).to have_css('.is-indeterminate')

          click_link 'bug'
          find('.dropdown-input-field', visible: true).set('wontfix')
          click_link 'wontfix'
        end

        update_issues

        page.within '.issues-holder' do
          expect(find("#issue_#{issue1.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'feature'
          expect(find("#issue_#{issue1.id}")).to have_content 'wontfix'

          expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'wontfix'
        end
      end
    end
  end

  context 'as a guest' do
    before do
      sign_in user

      visit project_issues_path(project)
    end

    context 'cannot bulk assign labels' do
      it do
        expect(page).not_to have_button 'Edit issues'
        expect(page).not_to have_css '.check-all-issues'
        expect(page).not_to have_css '.issue-check'
      end
    end
  end

  def open_milestone_dropdown(items = [])
    page.within('.issues-bulk-update') do
      click_button 'Select milestone'
      wait_for_requests
      items.map do |item|
        click_link item
      end
    end
  end

  def open_labels_dropdown(items = [], unmark = false)
    page.within('.issues-bulk-update') do
      click_button 'Select labels'
      wait_for_requests
      items.map do |item|
        click_link item
      end

      if unmark
        items.map do |item|
          # Make sure we are unmarking the item no matter the state it has currently
          click_link item until find('a', text: item)[:class] == 'label-item'
        end
      end
    end
  end

  def unmark_labels_in_dropdown(items = [])
    open_labels_dropdown(items, true)
  end

  def check_issue(issue, uncheck = false)
    page.within('.issues-list') do
      if uncheck
        uncheck "selected_issue_#{issue.id}"
      else
        check "selected_issue_#{issue.id}"
      end
    end
  end

  def uncheck_issue(issue)
    check_issue(issue, true)
  end

  def update_issues
    find('.update-selected-issues').click
    wait_for_requests
  end

  def enable_bulk_update
    visit project_issues_path(project)
    click_button 'Edit issues'
  end

  def disable_bulk_update
    click_button 'Cancel'
  end
end
