require 'rails_helper'

feature 'Issues > Labels bulk assignment', feature: true do
  include WaitForAjax

  let(:user)    { create(:user) }
  let!(:project) { create(:project) }
  let!(:issue1)  { create(:issue, project: project, title: "Issue 1") }
  let!(:issue2)  { create(:issue, project: project, title: "Issue 2") }

  before do
    create(:label, project: project, title: 'bug')
    create(:label, project: project, title: 'feature')
  end

  context 'as a allowed user', js: true do
    before do
      project.team << [user, :master]
      login_as user

      visit namespace_project_issues_path(project.namespace, project)
    end

    context 'can bulk assign a label' do
      context 'to all issues' do
        before do
          check 'check_all_issues'
          open_labels_dropdown ['bug']
          click_button 'Update issues'
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
          click_button 'Update issues'
        end

        it do
          expect(find("#issue_#{issue1.id}")).to have_content 'bug'
          expect(find("#issue_#{issue2.id}")).not_to have_content 'bug'
        end
      end
    end

    context 'can bulk assign multiple labels' do
      context 'to all issues' do
        before do
          check 'check_all_issues'
          open_labels_dropdown ['bug', 'feature']
          click_button 'Update issues'
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
          click_button 'Update issues'
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

  def open_labels_dropdown(items = [])
    page.within('.issues_bulk_update') do
      click_button 'Label'
      wait_for_ajax
      items.map do |item|
        click_link item
      end
    end
  end
end
