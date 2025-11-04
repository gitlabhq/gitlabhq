# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > Labels bulk assignment', feature_category: :team_planning do
  include ListboxHelpers

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

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'as an allowed user', :js do
    before do
      project.add_maintainer(user)

      sign_in user
    end

    context 'can bulk assign' do
      before do
        enable_bulk_update
      end

      context 'a label' do
        context 'to all issues' do
          before do
            check 'Select all'
            add_labels_with_dropdown ['bug']
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
            add_labels_with_dropdown ['bug']
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
            add_labels_with_dropdown ['bug']
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
            add_labels_with_dropdown %w[bug feature]
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
            add_labels_with_dropdown %w[bug feature]
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
        add_labels_with_dropdown ['bug']
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
          remove_labels_with_dropdown %w[bug feature]
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
          check issue1.title
          remove_labels_with_dropdown ['bug']
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
          check issue1.title
          check issue2.title
          remove_labels_with_dropdown ['bug']
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
          add_labels_with_dropdown ['feature']
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
          remove_labels_with_dropdown ['feature']
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

        check issue1.title
        add_labels_with_dropdown ['feature']
        uncheck issue1.title
        check issue1.title
        update_issues

        expect(find(issue_1_selector)).to have_content 'bug'
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
        remove_labels_with_dropdown ['bug']
        add_labels_with_dropdown ['wontfix']
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
    items.map do |item|
      select_listbox_item(item)
    end
  end

  def add_labels_with_dropdown(items = [])
    within_testid('bulk-edit-add-labels') do
      click_button 'Select labels'
      items.map do |item|
        select_listbox_item(item)
      end
      send_keys :escape
    end
  end

  def remove_labels_with_dropdown(items = [])
    within_testid('bulk-edit-remove-labels') do
      click_button 'Select labels'
      items.map do |item|
        select_listbox_item(item)
      end
      send_keys :escape
    end
  end

  def update_issues
    click_button 'Update selected'
  end

  def enable_bulk_update
    visit project_issues_path(project)
    click_button 'Bulk edit'
  end
end
