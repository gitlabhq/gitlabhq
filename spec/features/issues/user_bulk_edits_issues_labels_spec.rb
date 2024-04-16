# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > Labels bulk assignment', feature_category: :team_planning do
  let(:user)      { create(:user) }
  let!(:project)  { create(:project) }
  let!(:bug)      { create(:label, project: project, title: 'bug') }
  let!(:feature)  { create(:label, project: project, title: 'feature') }
  let!(:frontend) { create(:label, project: project, title: 'frontend') }
  let!(:wontfix)  { create(:label, project: project, title: 'wontfix') }
  let!(:issue1)   { create(:issue, project: project, title: "Issue 1", labels: [frontend]) }
  let!(:issue2)   { create(:issue, project: project, title: "Issue 2") }

  let(:issue_1_selector) { "#issuable_#{issue1.id}" }
  let(:issue_2_selector) { "#issuable_#{issue2.id}" }

  context 'as an allowed user', :js do
    before do
      project.add_maintainer(user)

      sign_in user
    end

    context 'sidebar' do
      it 'is present when bulk edit is enabled' do
        enable_bulk_update
        expect(page).to have_css 'aside[aria-label="Bulk update"]'
      end

      it 'is not present when bulk edit is disabled' do
        expect(page).not_to have_css 'aside[aria-label="Bulk update"]'
      end
    end

    context 'can bulk assign' do
      before do
        enable_bulk_update
      end

      context 'a label' do
        context 'to all issues' do
          before do
            check 'Select all'
            open_labels_dropdown ['bug']
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'frontend'
            expect(find(issue_2_selector)).to have_content 'bug'
            expect(find(issue_2_selector)).not_to have_content 'frontend'
          end
        end

        context 'to some issues' do
          before do
            check issue1.title
            check issue2.title
            open_labels_dropdown ['bug']
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'frontend'
            expect(find(issue_2_selector)).to have_content 'bug'
            expect(find(issue_2_selector)).not_to have_content 'frontend'
          end
        end

        context 'to an issue' do
          before do
            check issue1.title
            open_labels_dropdown ['bug']
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'frontend'
            expect(find(issue_2_selector)).not_to have_content 'bug'
            expect(find(issue_2_selector)).not_to have_content 'frontend'
          end
        end

        context 'to an issue by selecting the label first' do
          before do
            open_labels_dropdown ['bug']
            check issue1.title
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'frontend'
            expect(find(issue_2_selector)).not_to have_content 'bug'
            expect(find(issue_2_selector)).not_to have_content 'frontend'
          end
        end
      end

      context 'multiple labels' do
        context 'to all issues' do
          before do
            check 'Select all'
            open_labels_dropdown %w[bug feature]
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'feature'
            expect(find(issue_2_selector)).to have_content 'bug'
            expect(find(issue_2_selector)).to have_content 'feature'
          end
        end

        context 'to a issue' do
          before do
            check issue1.title
            open_labels_dropdown %w[bug feature]
            update_issues
          end

          it do
            expect(find(issue_1_selector)).to have_content 'bug'
            expect(find(issue_1_selector)).to have_content 'feature'
            expect(find(issue_2_selector)).not_to have_content 'bug'
            expect(find(issue_2_selector)).not_to have_content 'feature'
          end
        end
      end
    end

    context 'can assign a label to all issues when label is present' do
      before do
        issue2.labels << bug
        issue2.labels << feature

        enable_bulk_update
        check 'Select all'

        open_labels_dropdown ['bug']
        update_issues
      end

      it do
        expect(find(issue_1_selector)).to have_content 'bug'
        expect(find(issue_2_selector)).to have_content 'bug'
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
          check 'Select all'
          unmark_labels_in_dropdown %w[bug feature]
          update_issues
        end

        it do
          expect(find(issue_1_selector)).not_to have_content 'bug'
          expect(find(issue_1_selector)).not_to have_content 'feature'
          expect(find(issue_2_selector)).not_to have_content 'bug'
          expect(find(issue_2_selector)).not_to have_content 'feature'
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
          expect(find(issue_1_selector)).not_to have_content 'bug'
          expect(find(issue_2_selector)).to have_content 'feature'
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
          expect(find(issue_1_selector)).not_to have_content 'bug'
          expect(find(issue_1_selector)).to have_content 'feature'
          expect(find(issue_2_selector)).not_to have_content 'bug'
          expect(find(issue_2_selector)).to have_content 'feature'
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
          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_2_selector)).to have_content 'feature'

          check 'Select all'

          open_milestone_dropdown(['First Release'])
          update_issues

          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).to have_content 'First Release'
          expect(find(issue_2_selector)).to have_content 'feature'
          expect(find(issue_2_selector)).to have_content 'First Release'
        end
      end

      context 'setting a milestone and adding another label' do
        before do
          issue1.labels << bug
          enable_bulk_update
        end

        it 'keeps existing label and new label is present' do
          expect(find(issue_1_selector)).to have_content 'bug'

          check 'Select all'
          open_milestone_dropdown ['First Release']
          open_labels_dropdown ['feature']
          update_issues

          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).to have_content 'feature'
          expect(find(issue_1_selector)).to have_content 'First Release'
          expect(find(issue_2_selector)).to have_content 'feature'
          expect(find(issue_2_selector)).to have_content 'First Release'
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
          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_2_selector)).to have_content 'feature'

          check 'Select all'

          open_milestone_dropdown ['First Release']
          unmark_labels_in_dropdown ['feature']
          update_issues

          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).not_to have_content 'feature'
          expect(find(issue_1_selector)).to have_content 'First Release'
          expect(find(issue_2_selector)).not_to have_content 'feature'
          expect(find(issue_2_selector)).to have_content 'First Release'
        end
      end

      context 'unsetting a milestone' do
        before do
          issue1.milestone = milestone
          issue2.milestone = milestone
          issue1.save!
          issue2.save!
          issue1.labels << bug
          issue2.labels << feature

          enable_bulk_update
        end

        it 'keeps labels' do
          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).to have_content 'First Release'
          expect(find(issue_2_selector)).to have_content 'feature'
          expect(find(issue_2_selector)).to have_content 'First Release'

          check 'Select all'
          open_milestone_dropdown(['No milestone'])
          update_issues

          expect(find(issue_1_selector)).to have_content 'bug'
          expect(find(issue_1_selector)).not_to have_content 'First Release'
          expect(find(issue_2_selector)).to have_content 'feature'
          expect(find(issue_2_selector)).not_to have_content 'First Release'
        end
      end
    end

    context 'toggling checked issues' do
      before do
        issue1.labels << bug
        enable_bulk_update
      end

      it do
        expect(find(issue_1_selector)).to have_content 'bug'

        check_issue issue1
        open_labels_dropdown ['feature']
        uncheck_issue issue1
        check_issue issue1
        update_issues
        sleep 1 # needed

        expect(find(issue_1_selector)).to have_content 'bug'
        expect(find(issue_1_selector)).to have_content 'feature'
      end
    end

    context 'mark previously toggled label' do
      before do
        enable_bulk_update
      end

      it do
        open_labels_dropdown ['feature']

        check_issue issue1

        update_issues

        expect(find(issue_1_selector)).to have_content 'feature'
      end
    end

    # Special case https://gitlab.com/gitlab-org/gitlab-foss/issues/24877
    context 'unmarking common label' do
      before do
        issue1.labels << bug
        issue1.labels << feature
        issue2.labels << bug

        enable_bulk_update
      end

      it 'applies label from filtered results' do
        check 'Select all'

        within('aside[aria-label="Bulk update"]') do
          click_button 'Select labels'
          wait_for_requests

          expect(page).to have_link 'bug', class: 'is-active'
          expect(page).to have_link 'feature', class: 'is-indeterminate'

          click_link 'bug'
          fill_in 'Search', with: 'wontfix'
          click_link 'wontfix'
        end

        update_issues

        first_issue = find(issue_1_selector)
        expect(first_issue).not_to have_content 'bug'
        expect(first_issue).to have_content 'feature'
        expect(first_issue).to have_content 'wontfix'

        second_issue = find(issue_2_selector)
        expect(second_issue).not_to have_content 'bug'
        expect(second_issue).not_to have_content 'feature'
        expect(second_issue).to have_content 'wontfix'
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
        expect(page).not_to have_button 'Bulk edit'
        expect(page).not_to have_unchecked_field 'Select all'
        expect(page).not_to have_unchecked_field issue1.title
      end
    end
  end

  def open_milestone_dropdown(items = [])
    click_button 'Select milestone'
    wait_for_requests
    items.map do |item|
      click_button item
    end
  end

  def open_labels_dropdown(items = [], unmark = false)
    within('aside[aria-label="Bulk update"]') do
      click_button 'Select labels'
      wait_for_requests
      items.map do |item|
        click_link item
      end

      if unmark
        items.map do |item|
          # Make sure we are unmarking the item no matter the state it has currently
          click_link item until find('a', text: item)[:class].include? 'label-item'
        end
      end
    end
  end

  def unmark_labels_in_dropdown(items = [])
    open_labels_dropdown(items, true)
  end

  def check_issue(issue, uncheck = false)
    if uncheck
      uncheck issue.title
    else
      check issue.title
    end
  end

  def uncheck_issue(issue)
    check_issue(issue, true)
  end

  def update_issues
    click_button 'Update selected'
    wait_for_requests
  end

  def enable_bulk_update
    visit project_issues_path(project)
    wait_for_requests
    click_button 'Bulk edit'
  end

  def disable_bulk_update
    click_button 'Cancel'
  end
end
