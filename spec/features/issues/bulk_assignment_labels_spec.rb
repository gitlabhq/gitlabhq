require 'rails_helper'

feature 'Issues > Labels bulk assignment', feature: true do
  include WaitForAjax

  let(:user)      { create(:user) }
  let!(:project)  { create(:project) }
  let!(:issue1)   { create(:issue, project: project, title: "Issue 1") }
  let!(:issue2)   { create(:issue, project: project, title: "Issue 2") }
  let!(:bug)      { create(:label, project: project, title: 'bug') }
  let!(:feature)  { create(:label, project: project, title: 'feature') }

  context 'as an allowed user', js: true do
    before do
      project.team << [user, :master]

      login_as user
    end

    context 'can bulk assign' do
      before do
        visit namespace_project_issues_path(project.namespace, project)
      end

      context 'a label' do
        context 'to all issues' do
          before do
            check 'check_all_issues'
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
            check 'check_all_issues'
            open_labels_dropdown ['bug', 'feature']
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
            open_labels_dropdown ['bug', 'feature']
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
        visit namespace_project_issues_path(project.namespace, project)

        check 'check_all_issues'
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

          visit namespace_project_issues_path(project.namespace, project)

          check 'check_all_issues'
          unmark_labels_in_dropdown ['bug', 'feature']
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

          visit namespace_project_issues_path(project.namespace, project)

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

          visit namespace_project_issues_path(project.namespace, project)

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
          visit namespace_project_issues_path(project.namespace, project)
        end

        it 'keeps labels' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'

          check 'check_all_issues'
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

          visit namespace_project_issues_path(project.namespace, project)
        end

        it 'keeps existing label and new label is present' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'

          check 'check_all_issues'
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

          visit namespace_project_issues_path(project.namespace, project)
        end

        it 'keeps existing label and new label is present' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'

          check 'check_all_issues'
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

          visit namespace_project_issues_path(project.namespace, project)
        end

        it 'keeps labels' do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue1.id}")).to have_content 'First Release'
          expect(find("#issue_#{issue2.id}")).to have_content 'feature'
          expect(find("#issue_#{issue2.id}")).to have_content 'First Release'

          check 'check_all_issues'
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

        visit namespace_project_issues_path(project.namespace, project)
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
  end

  context 'as a guest' do
    before do
      login_as user

      visit namespace_project_issues_path(project.namespace, project)
    end

    context 'cannot bulk assign labels' do
      it do
        expect(page).not_to have_css '.check_all_issues'
        expect(page).not_to have_css '.issue-check'
      end
    end
  end

  def open_milestone_dropdown(items = [])
    page.within('.issues_bulk_update') do
      click_button 'Milestone'
      wait_for_ajax
      items.map do |item|
        click_link item
      end
    end
  end

  def open_labels_dropdown(items = [], unmark = false)
    page.within('.issues_bulk_update') do
      click_button 'Label'
      wait_for_ajax
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
    click_button 'Update issues'
    wait_for_ajax
  end
end
