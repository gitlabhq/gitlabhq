require 'spec_helper'

feature 'Issue prioritization' do
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

      sign_in user
      visit project_issues_path(project, sort: 'label_priority')

      # Ensure we are indicating that issues are sorted by priority
      expect(page).to have_selector('.dropdown-toggle', text: 'Label priority')

      page.within('.issues-holder') do
        issue_titles = all('.issues-list .issue-title-text').map(&:text)

        expect(issue_titles).to eq(%w(issue_4 issue_3 issue_5 issue_2 issue_1))
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

      sign_in user
      visit project_issues_path(project, sort: 'label_priority')

      expect(page).to have_selector('.dropdown-toggle', text: 'Label priority')

      page.within('.issues-holder') do
        issue_titles = all('.issues-list .issue-title-text').map(&:text)

        expect(issue_titles[0..1]).to contain_exactly('issue_5', 'issue_8')
        expect(issue_titles[2..4]).to contain_exactly('issue_1', 'issue_3', 'issue_7')
        expect(issue_titles[5..-1]).to eq(%w(issue_2 issue_4 issue_6))
      end
    end
  end
end
