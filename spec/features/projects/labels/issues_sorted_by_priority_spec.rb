# coding: utf-8
require 'spec_helper'

feature 'Issue prioritization', feature: true do

  let(:user)    { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }

  # Labels
  let(:label_1) { create(:label, title: 'label_1', project: project, priority: 1) }
  let(:label_2) { create(:label, title: 'label_2', project: project, priority: 2) }
  let(:label_3) { create(:label, title: 'label_3', project: project, priority: 3) }
  let(:label_4) { create(:label, title: 'label_4', project: project, priority: 4) }
  let(:label_5) { create(:label, title: 'label_5', project: project) } # no priority

  # According to https://gitlab.com/gitlab-org/gitlab-ce/issues/14189#note_4360653
  context 'when issues have one label' do
    scenario 'Are sorted properly' do

      # Issues
      issue_1 = create(:issue, title: 'issue_1', project: project)
      issue_2 = create(:issue, title: 'issue_2', project: project)
      issue_3 = create(:issue, title: 'issue_3', project: project)
      issue_4 = create(:issue, title: 'issue_4', project: project)
      issue_5 = create(:issue, title: 'issue_5', project: project)

      # Assign labels to issues disorderly
      issue_4.labels << label_1
      issue_3.labels << label_2
      issue_5.labels << label_3
      issue_2.labels << label_4
      issue_1.labels << label_5

      login_as user
      visit namespace_project_issues_path(project.namespace, project, sort: 'priority')

      # Ensure we are indicating that issues are sorted by priority
      expect(page).to have_selector('.dropdown-toggle', text: 'Priority')

      page.within('.issues-holder') do
        expect(page).to have_selector('.issues-list > li:nth-of-type(1)', text: 'issue_4')
        expect(page).to have_selector('.issues-list > li:nth-of-type(2)', text: 'issue_3')
        expect(page).to have_selector('.issues-list > li:nth-of-type(3)', text: 'issue_5')
        expect(page).to have_selector('.issues-list > li:nth-of-type(4)', text: 'issue_2')

        # the rest should be at the bottom
        expect(page).to have_selector('.issues-list > li:nth-of-type(5)', text: 'issue_1')
      end
    end
  end

  context 'when issues have multiple labels' do
    scenario 'Are sorted properly' do

      # Issues
      issue_1 = create(:issue, title: 'issue_1', project: project)
      issue_2 = create(:issue, title: 'issue_2', project: project)
      issue_3 = create(:issue, title: 'issue_3', project: project)
      issue_4 = create(:issue, title: 'issue_4', project: project)
      issue_5 = create(:issue, title: 'issue_5', project: project)
      issue_6 = create(:issue, title: 'issue_6', project: project)
      issue_7 = create(:issue, title: 'issue_7', project: project)
      issue_8 = create(:issue, title: 'issue_8', project: project)

      # Assign labels to issues disorderly
      issue_5.labels << label_1 # 1
      issue_5.labels << label_2
      issue_8.labels << label_1 # 2
      issue_1.labels << label_2 # 3
      issue_1.labels << label_3
      issue_3.labels << label_2 # 4
      issue_3.labels << label_4
      issue_7.labels << label_2 # 5
      issue_2.labels << label_3 # 6
      issue_4.labels << label_4 # 7
      issue_6.labels << label_5 # 8 - No priority

      login_as user
      visit namespace_project_issues_path(project.namespace, project, sort: 'priority')

      expect(page).to have_selector('.dropdown-toggle', text: 'Priority')

      page.within('.issues-holder') do
        expect(page).to have_selector('.issues-list > li:nth-of-type(1)', text: 'issue_5')
        expect(page).to have_selector('.issues-list > li:nth-of-type(2)', text: 'issue_8')
        expect(page).to have_selector('.issues-list > li:nth-of-type(3)', text: 'issue_1')
        expect(page).to have_selector('.issues-list > li:nth-of-type(4)', text: 'issue_3')
        expect(page).to have_selector('.issues-list > li:nth-of-type(5)', text: 'issue_7')
        expect(page).to have_selector('.issues-list > li:nth-of-type(6)', text: 'issue_2')
        expect(page).to have_selector('.issues-list > li:nth-of-type(7)', text: 'issue_4')
        expect(page).to have_selector('.issues-list > li:nth-of-type(8)', text: 'issue_6')
      end
    end
  end
end
